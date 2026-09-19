import Foundation
import Testing
@testable import lab_ios_Pinning

@Suite
struct LabConfigurationTests {
    @Test
    func parsesHostedValuesAndMultiplePins() throws {
        let first = "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        let second = "sha256/AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE="

        let configuration = try LabConfiguration.parse([
            "LabHTTPURL": "http://zsk.labs.def.dev/pinning/success",
            "LabHTTPSURL": "https://zsk.labs.def.dev/pinning/success",
            "LabSPKIPins": "\(first), \(second)",
        ])

        #expect(configuration.pinnedHost == "zsk.labs.def.dev")
        #expect(configuration.pins.count == 2)
    }

    @Test
    func rejectsMissingPins() {
        #expect(throws: LabConfigurationError.missingPins) {
            try LabConfiguration.parse([
                "LabHTTPURL": "http://zsk.labs.def.dev/pinning/success",
                "LabHTTPSURL": "https://zsk.labs.def.dev/pinning/success",
            ])
        }
    }
}

@Suite
struct SPKIPinTests {
    @Test
    func parsesAndFormatsSHA256Pin() throws {
        let value = "sha256/AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE="
        #expect(try SPKIPin(value).description == value)
    }

    @Test
    func rejectsWrongDigestLength() {
        #expect(throws: (any Error).self) {
            try SPKIPin("sha256/AQ==")
        }
    }

    @Test
    func p256SPKIHashVector() throws {
        let rawPublicKey = Data([0x04] + Array(repeating: 0, count: 64))
        let pin = try SPKIHasher.pin(p256PublicKey: rawPublicKey)
        #expect(pin.description == "sha256/FhPubfxu6YoU7IG0Hq45pUOLUPvLv4oAgUflVyabRMs=")
    }
}

@MainActor
@Suite
struct ContentViewModelTests {
    @Test
    func pinnedScenarioUsesPinnedClientAndHTTPSURL() async {
        let systemClient = RecordingNetworkService(response: Data("system".utf8))
        let pinnedClient = RecordingNetworkService(response: Data("pinned".utf8))
        let configuration = LabConfiguration(
            httpURL: URL(string: "http://example.test/pinning/success")!,
            httpsURL: URL(string: "https://example.test/pinning/success")!,
            pins: []
        )
        let viewModel = ContentViewModel(
            configuration: configuration,
            systemClient: systemClient,
            pinnedClient: pinnedClient
        )

        viewModel.pinnedCertificateConnection()
        while viewModel.isLoading {
            await Task.yield()
        }

        #expect(viewModel.requestURL == configuration.httpsURL.absoluteString)
        #expect(viewModel.requestProgress == "pinned")
        let pinnedRequests = await pinnedClient.requestedURLs()
        let systemRequests = await systemClient.requestedURLs()
        #expect(pinnedRequests == [configuration.httpsURL])
        #expect(systemRequests == [])
    }
}

private actor RecordingNetworkService: NetworkServiceProtocol {
    private let response: Data
    private var requests: [URL] = []

    init(response: Data) {
        self.response = response
    }

    func process(request: URLRequest) async throws -> Data {
        if let url = request.url {
            requests.append(url)
        }
        return response
    }

    func requestedURLs() -> [URL] {
        requests
    }
}