import Foundation

struct LabConfiguration: Equatable, Sendable {
    let pinningURL: URL
    let baselineLeafPin: String

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
              url.host() != nil
        else {
            throw LabConfigurationError.invalidPinningURL
        }
        guard let pin = values["LabLeafPin"] as? String,
              (try? SPKIPin(pin)) != nil
        else {
            throw LabConfigurationError.invalidLeafPin
        }
        return LabConfiguration(pinningURL: url, baselineLeafPin: pin)
    }

    static let fallback = LabConfiguration(
        pinningURL: URL(string: "https://zsk.labs.def.dev/pinning/success")!,
        baselineLeafPin: "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    )
}

enum LabConfigurationError: LocalizedError, Equatable {
    case invalidPinningURL
    case invalidLeafPin

    var errorDescription: String? {
        switch self {
        case .invalidPinningURL:
            "LabPinningURL must contain a valid https URL."
        case .invalidLeafPin:
            "LabLeafPin must contain a sha256/ Base64 SPKI pin."
        }
    }
}

enum AppRepository {
    @MainActor
    static func makeViewModel(bundle: Bundle = .main) -> ContentViewModel {
        let audit = PinAudit()
        do {
            let configuration = try LabConfiguration.load(from: bundle)
            return makeViewModel(configuration: configuration, audit: audit)
        } catch {
            return makeViewModel(
                configuration: .fallback,
                audit: audit,
                initialResult: "Configuration error: \(error.localizedDescription)"
            )
        }
    }

    @MainActor
    private static func makeViewModel(
        configuration: LabConfiguration,
        audit: PinAudit,
        initialResult: String? = nil
    ) -> ContentViewModel {
        ContentViewModel(
            configuration: configuration,
            pinnedLeaf: PinnedLeafStore(),
            clientFactory: PinnedClientFactory(
                expectedHost: configuration.pinnedHost,
                audit: audit
            ),
            audit: audit,
            initialResult: initialResult
        )
    }
}
