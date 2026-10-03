import Foundation

struct NetworkResponse: Sendable {
    let body: Data
    let protocolName: String?
}

protocol NetworkServiceProtocol: Sendable {
    func process(request: URLRequest) async throws -> NetworkResponse
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

private actor ProtocolRecorder {
    private var name: String?

    func record(_ value: String?) {
        name = value
    }

    func current() -> String? {
        name
    }
}

private final class MetricsDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let recorder: ProtocolRecorder

    init(recorder: ProtocolRecorder) {
        self.recorder = recorder
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
    ) {
        let name = metrics.transactionMetrics.last?.networkProtocolName
        let recorder = self.recorder
        Task {
            await recorder.record(name)
        }
    }
}

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func process(request: URLRequest) async throws -> NetworkResponse {
        var request = request
        request.assumesHTTP3Capable = true
        let recorder = ProtocolRecorder()
        let (data, response) = try await session.data(
            for: request,
            delegate: MetricsDelegate(recorder: recorder)
        )
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.nonHTTPResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkServiceError.unexpectedStatus(httpResponse.statusCode)
        }
        return NetworkResponse(body: data, protocolName: await protocolName(from: recorder))
    }

    private func protocolName(from recorder: ProtocolRecorder) async -> String? {
        for _ in 0..<20 {
            if let name = await recorder.current() {
                return name
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return nil
    }
}
