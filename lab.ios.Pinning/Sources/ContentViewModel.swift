import Foundation
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @Published private(set) var requestURL: String?
    @Published private(set) var requestProgress: String?
    @Published private(set) var isLoading = false

    private let configuration: LabConfiguration
    private let systemClient: any NetworkServiceProtocol
    private let pinnedClient: any NetworkServiceProtocol
    private var requestTask: Task<Void, Never>?

    init(
        configuration: LabConfiguration,
        systemClient: any NetworkServiceProtocol,
        pinnedClient: any NetworkServiceProtocol,
        initialMessage: String? = nil
    ) {
        self.configuration = configuration
        self.systemClient = systemClient
        self.pinnedClient = pinnedClient
        requestProgress = initialMessage
    }

    func plainTextConnection() {
        process(url: configuration.httpURL, using: systemClient)
    }

    func osStoreConnection() {
        process(url: configuration.httpsURL, using: systemClient)
    }

    func pinnedCertificateConnection() {
        process(url: configuration.httpsURL, using: pinnedClient)
    }

    func cancelRequest() {
        requestTask?.cancel()
        requestTask = nil
        isLoading = false
    }

    private func process(url: URL, using client: any NetworkServiceProtocol) {
        requestTask?.cancel()
        requestURL = url.absoluteString
        requestProgress = "Connecting…"
        isLoading = true

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        requestTask = Task { [weak self] in
            do {
                let data = try await client.process(request: request)
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
