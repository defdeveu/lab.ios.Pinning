import Foundation
import Combine

class ContentViewModel: ObservableObject {
    
    @Published var requestUrl: String?
    @Published var requestProgress: String?
    @Published var isLoading: Bool = false
    
    private var subscriptions = Set<AnyCancellable>()
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
}

// MARK: - Network requests

extension ContentViewModel {
    func plainTextConnection() {
        requestProgress = "As calls to plain http in form 'http://3.127.138.254' cannot be catched by ATS (NSAppTransportSecurity) we have to remove such urls."
    }
    
    func osStoreConnection() {
        requestProgress = "Downloading using OS store CA validation..."
        process(url: "https://zs.labs.defdev.eu/success.html")
    }
    
    func pinnedCertificateConnection() {
        requestProgress = "Tapped Pinned Cert.Getting content from remote server..."
        process(url: "https://zs2.labs.defdev.eu:444/success.html")
    }
}

// MARK: - Helpers

extension ContentViewModel {
    private func process(url urlString: String) {
        guard let url = URL(string: urlString)
        else {
            requestProgress = "Invalid url"
            return
        }

        requestUrl = url.absoluteString
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
        
        isLoading = true

        networkService.process(request: request)
            .sink { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.requestProgress = error.localizedDescription
                case .finished:
                    break
                }
                self?.isLoading = false
            } receiveValue: { [weak self] data in
                self?.requestProgress = String(data: data, encoding: .utf8)
            }
            .store(in: &subscriptions)
    }
}
