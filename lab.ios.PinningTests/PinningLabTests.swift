import Foundation
import XCTest
@testable import lab_ios_Pinning

final class LabConfigurationTests: XCTestCase {
    func testParsesHostedURLs() throws {
        let configuration = try LabConfiguration.parse([
            "LabHTTPURL": "http://zsk.labs.def.dev/pinning/success",
            "LabHTTPSURL": "https://zsk.labs.def.dev/pinning/success",
        ])

        XCTAssertEqual(configuration.httpURL.scheme, "http")
        XCTAssertEqual(configuration.httpsURL.scheme, "https")
        XCTAssertEqual(configuration.httpsURL.host(), "zsk.labs.def.dev")
    }

    func testRejectsWrongHTTPScheme() {
        XCTAssertThrowsError(try LabConfiguration.parse([
            "LabHTTPURL": "http://zsk.labs.def.dev/pinning/success",
            "LabHTTPSURL": "http://zsk.labs.def.dev/pinning/success",
        ])) { error in
            XCTAssertEqual(error as? LabConfigurationError, .invalidHTTPSURL)
        }
    }
}

@MainActor
final class ContentViewModelTests: XCTestCase {
    func testOSStoreScenarioUsesConfiguredHTTPSURL() async {
        let client = RecordingNetworkService(response: Data("response".utf8))
        let configuration = LabConfiguration(
            httpURL: URL(string: "http://example.test/pinning/success")!,
            httpsURL: URL(string: "https://example.test/pinning/success")!
        )
        let viewModel = ContentViewModel(
            configuration: configuration,
            networkService: client
        )

        viewModel.osStoreConnection()
        while viewModel.isLoading {
            await Task.yield()
        }

        let requests = await client.requestedURLs()
        XCTAssertEqual(viewModel.requestURL, configuration.httpsURL.absoluteString)
        XCTAssertEqual(viewModel.requestProgress, "response")
        XCTAssertEqual(requests, [configuration.httpsURL])
    }
}

private actor RecordingNetworkService: NetworkServiceProtocol {
    private let response: Data
    private var requests: [URL] = []

    init(response: Data) {
        self.response = response
    }

    func process(request: URLRequest) async throws -> Data {
        if let url = request.url {
            requests.append(url)
        }
        return response
    }

    func requestedURLs() -> [URL] {
        requests
    }
}
