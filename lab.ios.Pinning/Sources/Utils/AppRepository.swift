import Foundation

struct LabConfiguration: Equatable, Sendable {
    let httpURL: URL
    let httpsURL: URL

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
        return LabConfiguration(httpURL: httpURL, httpsURL: httpsURL)
    }

    static let fallback = LabConfiguration(
        httpURL: URL(string: "http://zsk.labs.def.dev/pinning/success")!,
        httpsURL: URL(string: "https://zsk.labs.def.dev/pinning/success")!
    )
}

enum LabConfigurationError: LocalizedError, Equatable {
    case invalidHTTPURL
    case invalidHTTPSURL

    var errorDescription: String? {
        switch self {
        case .invalidHTTPURL:
            "LabHTTPURL must contain a valid http URL."
        case .invalidHTTPSURL:
            "LabHTTPSURL must contain a valid https URL."
        }
    }
}

enum AppRepository {
    @MainActor
    static func makeViewModel(bundle: Bundle = .main) -> ContentViewModel {
        do {
            let configuration = try LabConfiguration.load(from: bundle)
            return ContentViewModel(
                configuration: configuration,
                networkService: NetworkService()
            )
        } catch {
            return ContentViewModel(
                configuration: .fallback,
                networkService: NetworkService(),
                initialMessage: "Configuration error: \(error.localizedDescription)"
            )
        }
    }
}
