import Foundation
import Observation

@MainActor
@Observable
final class ContentViewModel {
    private(set) var isConnecting = false
    private(set) var result: String?
    private(set) var negotiatedProtocol: String?

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
        negotiatedProtocol = nil

        let request = URLRequest(url: configuration.pinningURL, cachePolicy: .reloadIgnoringLocalCacheData)
        let networkService = self.networkService
        Task { [weak self] in
            do {
                let response = try await networkService.process(request: request)
                self?.result = String(decoding: response.body, as: UTF8.self)
                self?.negotiatedProtocol = response.protocolName
            } catch {
                self?.result = error.localizedDescription
            }
            self?.isConnecting = false
        }
    }
}
