import Foundation
import Observation

@MainActor
@Observable
final class ContentViewModel {
    private(set) var effectiveLeafPin: String
    private(set) var isConnecting = false
    private(set) var result: String?

    @ObservationIgnored private let configuration: LabConfiguration
    @ObservationIgnored private let pinnedLeaf: PinnedLeafStore
    @ObservationIgnored private let clientFactory: any PinnedClientMaking
    @ObservationIgnored private let audit: PinAudit
    @ObservationIgnored private var connectTask: Task<Void, Never>?

    init(
        configuration: LabConfiguration,
        pinnedLeaf: PinnedLeafStore,
        clientFactory: any PinnedClientMaking,
        audit: PinAudit,
        initialResult: String? = nil
    ) {
        self.configuration = configuration
        self.pinnedLeaf = pinnedLeaf
        self.clientFactory = clientFactory
        self.audit = audit
        effectiveLeafPin = pinnedLeaf.effectivePin(baseline: configuration.baselineLeafPin)
        result = initialResult
    }

    func restoreLeafPin() {
        pinnedLeaf.restore()
        effectiveLeafPin = configuration.baselineLeafPin
        result = "Baseline leaf pin restored; Connect should succeed again."
    }

    func breakLeafPin() {
        var generator = SystemRandomNumberGenerator()
        let broken = LeafPinSimulator.broken(configuration.baselineLeafPin, using: &generator)
        pinnedLeaf.store(broken)
        effectiveLeafPin = broken
        result = "Effective leaf pin changed; Connect now to watch a leaf-pin mismatch."
    }

    func connect() {
        guard !isConnecting else {
            return
        }
        guard let pin = try? SPKIPin(effectiveLeafPin) else {
            result = "The effective leaf pin is not a valid sha256/ pin."
            return
        }

        connectTask?.cancel()
        isConnecting = true
        result = nil
        let request = URLRequest(url: configuration.pinningURL, cachePolicy: .reloadIgnoringLocalCacheData)
        let client = clientFactory.makeClient(effectivePin: pin)
        connectTask = Task { [weak self] in
            do {
                let data = try await client.process(request: request)
                try Task.checkCancellation()
                self?.result = String(decoding: data, as: UTF8.self)
            } catch is CancellationError {
                return
            } catch {
                guard let self else {
                    return
                }
                if let rejection = audit.take() {
                    result = Self.message(for: rejection, host: configuration.pinnedHost)
                } else {
                    result = error.localizedDescription
                }
            }
            self?.isConnecting = false
            self?.connectTask = nil
        }
    }

    private static func message(for rejection: PinRejection, host: String) -> String {
        switch rejection {
        case let .hostMismatch(expected):
            "Connection rejected: the server host is not \(expected)."
        case .trustEvaluationFailed:
            "Connection rejected: platform trust evaluation failed for the served chain."
        case .unsupportedKey:
            "Connection rejected: the served certificate does not use a supported P-256 key."
        case .pinMismatch:
            "Connection rejected: the served leaf key does not match the effective leaf pin. This is what a certificate change looks like to a leaf pin."
        }
    }
}
