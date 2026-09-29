import Foundation

struct PinnedIdentity: Equatable, Sendable {
    let host: String
    let digests: [String]
}

struct LabConfiguration: Equatable, Sendable {
    let pinningURL: URL
    let pinnedIdentity: PinnedIdentity?

    var pinnedHost: String {
        pinningURL.host() ?? ""
    }

    static func load(from bundle: Bundle = .main) throws -> LabConfiguration {
        try parse(bundle.infoDictionary ?? [:])
    }

    static func parse(_ values: [String: Any]) throws -> LabConfiguration {
        guard let urlValue = values["LabPinningURL"] as? String,
              let url = URL(string: urlValue),
              url.scheme == "https",
              let host = url.host()
        else {
            throw LabConfigurationError.invalidPinningURL
        }
        guard let identity = pinnedIdentity(from: values["NSAppTransportSecurity"], host: host) else {
            throw LabConfigurationError.missingPinnedIdentity(host)
        }
        return LabConfiguration(pinningURL: url, pinnedIdentity: identity)
    }

    static func pinnedIdentity(from transportSecurity: Any?, host: String) -> PinnedIdentity? {
        guard let transportSecurity = transportSecurity as? [String: Any],
              let pinnedDomains = transportSecurity["NSPinnedDomains"] as? [String: Any],
              let domain = pinnedDomains[host] as? [String: Any],
              let identities = domain["NSPinnedCAIdentities"] as? [[String: Any]]
        else {
            return nil
        }
        let digests = identities.compactMap { $0["SPKI-SHA256-BASE64"] as? String }
        guard !digests.isEmpty else {
            return nil
        }
        return PinnedIdentity(host: host, digests: digests)
    }

    static let fallback = LabConfiguration(
        pinningURL: URL(string: "https://zsk.labs.def.dev/pinning/success")!,
        pinnedIdentity: nil
    )
}

enum LabConfigurationError: LocalizedError, Equatable {
    case invalidPinningURL
    case missingPinnedIdentity(String)

    var errorDescription: String? {
        switch self {
        case .invalidPinningURL:
            "LabPinningURL must contain a valid https URL."
        case let .missingPinnedIdentity(host):
            "Info.plist must pin the issuing CA keys for \(host) under NSAppTransportSecurity."
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
                initialResult: "Configuration error: \(error.localizedDescription)"
            )
        }
    }
}
