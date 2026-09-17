import Foundation

struct LabConfiguration: Equatable, Sendable {
    let httpURL: URL
    let httpsURL: URL
    let pins: Set<SPKIPin>

    var pinnedHost: String {
        httpsURL.host() ?? ""
    }

    static func load(from bundle: Bundle = .main) throws -> LabConfiguration {
        try parse(bundle.infoDictionary ?? [:])
    }

    static func parse(_ values: [String: Any]) throws -> LabConfiguration {
        guard let httpValue = values["LabHTTPURL"] as? String,
              let httpURL = URL(string: httpValue),
              httpURL.scheme == "http"
        else {
            throw LabConfigurationError.invalidHTTPURL
        }
        guard let httpsValue = values["LabHTTPSURL"] as? String,
              let httpsURL = URL(string: httpsValue),
              httpsURL.scheme == "https",
              httpsURL.host() != nil
        else {
            throw LabConfigurationError.invalidHTTPSURL
        }
        let rawPins = (values["LabSPKIPins"] as? String) ?? ""
        let pins = try Set(
            rawPins
                .split(separator: ",")
                .map { try SPKIPin(String($0).trimmingCharacters(in: .whitespaces)) }
        )
        guard !pins.isEmpty else {
            throw LabConfigurationError.missingPins
        }
        return LabConfiguration(httpURL: httpURL, httpsURL: httpsURL, pins: pins)
    }

    static let fallback = LabConfiguration(
        httpURL: URL(string: "http://zsk.labs.def.dev/pinning/success")!,
        httpsURL: URL(string: "https://zsk.labs.def.dev/pinning/success")!,
        pins: []
    )
}

enum LabConfigurationError: LocalizedError, Equatable {
    case invalidHTTPURL
    case invalidHTTPSURL
    case missingPins

    var errorDescription: String? {
        switch self {
        case .invalidHTTPURL:
            "LabHTTPURL must contain a valid http URL."
        case .invalidHTTPSURL:
            "LabHTTPSURL must contain a valid https URL."
        case .missingPins:
            "LabSPKIPins must contain at least one sha256/ Base64 SPKI pin."
        }
    }
}

enum AppRepository {
    @MainActor
    static func makeViewModel(bundle: Bundle = .main) -> ContentViewModel {
        do {
            let configuration = try LabConfiguration.load(from: bundle)
            let systemClient = NetworkService()
            let delegate = SessionPinningDelegate(
                expectedHost: configuration.pinnedHost,
                allowedPins: configuration.pins
            )
            let session = URLSession(
                configuration: .ephemeral,
                delegate: delegate,
                delegateQueue: nil
            )
            return ContentViewModel(
                configuration: configuration,
                systemClient: systemClient,
                pinnedClient: NetworkService(session: session)
            )
        } catch {
            let client = NetworkService()
            return ContentViewModel(
                configuration: .fallback,
                systemClient: client,
                pinnedClient: client,
                initialMessage: "Configuration error: \(error.localizedDescription)"
            )
        }
    }
}
