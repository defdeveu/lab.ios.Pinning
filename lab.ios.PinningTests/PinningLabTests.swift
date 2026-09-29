import Foundation
import Testing
@testable import lab_ios_Pinning

private let validPin = "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

@Suite
struct LabConfigurationTests {
    @Test
    func parsesTheHostedConfiguration() throws {
        let configuration = try LabConfiguration.parse([
            "LabPinningURL": "https://zsk.labs.def.dev/pinning/success",
            "LabLeafPin": validPin,
        ])

        #expect(configuration.pinningURL.host() == "zsk.labs.def.dev")
        #expect(configuration.pinnedHost == "zsk.labs.def.dev")
        #expect(configuration.baselineLeafPin == validPin)
    }

    @Test
    func rejectsANonHTTPSPinningURL() {
        #expect(throws: LabConfigurationError.invalidPinningURL) {
            try LabConfiguration.parse([
                "LabPinningURL": "http://zsk.labs.def.dev/pinning/success",
                "LabLeafPin": validPin,
            ])
        }
    }

    @Test
    func rejectsAPinWithoutTheExpectedShape() {
        #expect(throws: LabConfigurationError.invalidLeafPin) {
            try LabConfiguration.parse([
                "LabPinningURL": "https://zsk.labs.def.dev/pinning/success",
                "LabLeafPin": "not-a-pin",
            ])
        }
    }
}

@Suite
struct LeafPinSimulatorTests {
    @Test
    func breakChangesExactlySevenPayloadCharacters() throws {
        var generator = SeededGenerator(seed: 42)
        let broken = LeafPinSimulator.broken(validPin, using: &generator)

        #expect(broken != validPin)
        #expect(broken.hasPrefix("sha256/"))
        #expect(broken.hasSuffix("="))
        let parsed = try SPKIPin(broken)
        #expect(parsed != (try SPKIPin(validPin)))

        let differing = zip(validPin, broken).filter { $0 != $1 }.count
        #expect(differing == LeafPinSimulator.brokenCharacterCount)
    }

    @Test
    func repeatedBreaksOfTheBaselineDiffer() {
        var first = SeededGenerator(seed: 1)
        var second = SeededGenerator(seed: 2)
        let one = LeafPinSimulator.broken(validPin, using: &first)
        let other = LeafPinSimulator.broken(validPin, using: &second)
        #expect(one != other)
    }
}

@Suite
struct PinnedLeafStoreTests {
    @Test
    func storeAndRestoreRoundTripTheEffectivePin() throws {
        let suiteName = "lab.ios.Pinning.tests.store.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PinnedLeafStore(defaults: defaults)

        #expect(store.effectivePin(baseline: validPin) == validPin)
        store.store("sha256/QUJD")
        #expect(store.effectivePin(baseline: validPin) == "sha256/QUJD")
        store.restore()
        #expect(store.effectivePin(baseline: validPin) == validPin)
    }
}

@Suite
struct PinAuditTests {
    @Test
    func takeConsumesTheRecordedRejection() {
        let audit = PinAudit()
        #expect(audit.take() == nil)
        audit.record(.pinMismatch)
        #expect(audit.take() == .pinMismatch)
        #expect(audit.take() == nil)
    }
}

@MainActor
@Suite
struct ContentViewModelTests {
    @Test
    func connectUsesTheEffectivePinAndShowsTheResponse() async throws {
        let factory = RecordingClientFactory(client: StubNetworkService { _ in
            Data("Connection succeeded.".utf8)
        })
        let viewModel = makeViewModel(factory: factory)

        viewModel.connect()
        while viewModel.isConnecting {
            await Task.yield()
        }

        #expect(viewModel.result == "Connection succeeded.")
        #expect(factory.recordedPins() == [try SPKIPin(validPin)])
    }

    @Test
    func aCancelledChallengeShowsTheRecordedExplanation() async {
        let audit = PinAudit()
        let factory = RecordingClientFactory(client: StubNetworkService { _ in
            audit.record(.pinMismatch)
            throw URLError(.cancelled)
        })
        let viewModel = makeViewModel(factory: factory, audit: audit)

        viewModel.connect()
        while viewModel.isConnecting {
            await Task.yield()
        }

        #expect(viewModel.result?.contains("does not match the effective leaf pin") == true)
    }

    @Test
    func breakPersistsAMutatedPinAndRestoreRecovers() throws {
        let suiteName = "lab.ios.Pinning.tests.viewmodel.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PinnedLeafStore(defaults: defaults)
        let factory = RecordingClientFactory(client: StubNetworkService { _ in Data() })
        let viewModel = makeViewModel(factory: factory, store: store)

        viewModel.breakLeafPin()
        #expect(viewModel.effectiveLeafPin != validPin)
        #expect(store.effectivePin(baseline: validPin) == viewModel.effectiveLeafPin)

        viewModel.restoreLeafPin()
        #expect(viewModel.effectiveLeafPin == validPin)
        #expect(store.effectivePin(baseline: validPin) == validPin)
    }

    private func makeViewModel(
        factory: RecordingClientFactory,
        store: PinnedLeafStore? = nil,
        audit: PinAudit = PinAudit()
    ) -> ContentViewModel {
        let defaults = UserDefaults(suiteName: "lab.ios.Pinning.tests.ephemeral.\(UUID().uuidString)")!
        return ContentViewModel(
            configuration: LabConfiguration(
                pinningURL: URL(string: "https://example.test/pinning/success")!,
                baselineLeafPin: validPin
            ),
            pinnedLeaf: store ?? PinnedLeafStore(defaults: defaults),
            clientFactory: factory,
            audit: audit
        )
    }
}

private final class RecordingClientFactory: PinnedClientMaking, @unchecked Sendable {
    private let lock = NSLock()
    private var pins: [SPKIPin] = []
    private let client: any NetworkServiceProtocol

    init(client: any NetworkServiceProtocol) {
        self.client = client
    }

    func makeClient(effectivePin: SPKIPin) -> any NetworkServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        pins.append(effectivePin)
        return client
    }

    func recordedPins() -> [SPKIPin] {
        lock.lock()
        defer { lock.unlock() }
        return pins
    }
}

private struct StubNetworkService: NetworkServiceProtocol {
    let handler: @Sendable (URLRequest) async throws -> Data

    func process(request: URLRequest) async throws -> Data {
        try await handler(request)
    }
}
