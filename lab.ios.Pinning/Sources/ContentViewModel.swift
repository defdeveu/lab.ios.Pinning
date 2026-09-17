import Combine
import Foundation

@MainActor
final class ContentViewModel: ObservableObject {
    @Published private(set) var requestURL: String?
    @Published private(set) var requestProgress: String?
    @Published private(set) var isLoading = false

    private let configuration: LabConfiguration
    private let networkService: any NetworkServiceProtocol
    private var requestTask: Task<Void, Never>?

    init(
        configuration: LabConfiguration,
        networkService: any NetworkServiceProtocol,
        initialMessage: String? = nil
    ) {
        self.configuration = configuration
        self.networkService = networkService
        requestProgress = initialMessage
    }

    func plainTextConnection() {
        process(url: configuration.httpURL)
    }

    func osStoreConnection() {
        process(url: configuration.httpsURL)
    }

    func pinnedCertificateConnection() {
        process(url: configuration.httpsURL)
    }

    func cancelRequest() {
        requestTask?.cancel()
        requestTask = nil
        isLoading = false
    }

    private func process(url: URL) {
        requestTask?.cancel()
        requestURL = url.absoluteString
        requestProgress = "Connecting…"
        isLoading = true

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let networkService = self.networkService
        requestTask = Task { [weak self] in
            do {
                let data = try await networkService.process(request: request)
                try Task.checkCancellation()
                self?.requestProgress = String(decoding: data, as: UTF8.self)
            } catch is CancellationError {
                return
            } catch {
                self?.requestProgress = error.localizedDescription
            }
            self?.isLoading = false
            self?.requestTask = nil
        }
    }
}
