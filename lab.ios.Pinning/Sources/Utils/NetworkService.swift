import Foundation

protocol NetworkServiceProtocol: Sendable {
    func process(request: URLRequest) async throws -> Data
}

enum NetworkServiceError: LocalizedError, Equatable {
    case nonHTTPResponse
    case unexpectedStatus(Int)

    var errorDescription: String? {
        switch self {
        case .nonHTTPResponse:
            "The server did not return an HTTP response."
        case let .unexpectedStatus(status):
            "The server returned HTTP status \(status)."
        }
    }
}

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func process(request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.nonHTTPResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkServiceError.unexpectedStatus(httpResponse.statusCode)
        }
        return data
    }
}
