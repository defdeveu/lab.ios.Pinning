import Foundation

// MARK: - Application Services

final class AppRepository {
    static var shared = AppRepository()
    private init() { }

    private lazy var sessionPinningDelegate: URLSessionDelegate = SessionPinningDelegate()

    lazy var networkService: NetworkServiceProtocol = {
        let session = URLSession(
                    configuration: URLSessionConfiguration.ephemeral,
                    delegate: sessionPinningDelegate,
                    delegateQueue: nil)
        return NetworkService(session: session)
    }()
}
