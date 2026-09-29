import Foundation
import Observation

@MainActor
@Observable
final class ContentViewModel {
    private(set) var isConnecting = false
    private(set) var result: String?

    @ObservationIgnored private let configuration: LabConfiguration
    @ObservationIgnored private let networkService: any NetworkServiceProtocol

    init(
        configuration: LabConfiguration,
        networkService: any NetworkServiceProtocol,
        initialResult: String? = nil
    ) {
        self.configuration = configuration
        self.networkService = networkService
        result = initialResult
    }

    var checkedAgainstHost: String {
        configuration.pinnedIdentity?.host ?? configuration.pinnedHost
    }

    var checkedAgainstDigests: [String] {
        configuration.pinnedIdentity?.digests.map { "sha256/\($0)" } ?? []
    }

    func connect() {
        guard !isConnecting else {
            return
        }
        isConnecting = true
        result = nil

        let request = URLRequest(url: configuration.pinningURL, cachePolicy: .reloadIgnoringLocalCacheData)
        let networkService = self.networkService
        Task { [weak self] in
            do {
                let data = try await networkService.process(request: request)
                self?.result = String(decoding: data, as: UTF8.self)
            } catch {
                self?.result = error.localizedDescription
            }
            self?.isConnecting = false
        }
    }
}
