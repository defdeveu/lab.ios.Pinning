import Foundation
import Testing
@testable import lab_ios_Pinning

@Suite
struct LabConfigurationTests {
    @Test
    func parsesHostedURLs() throws {
        let configuration = try LabConfiguration.parse([
            "LabHTTPURL": "http://zsk.labs.def.dev/pinning/success",
            "LabHTTPSURL": "https://zsk.labs.def.dev/pinning/success",
        ])

        #expect(configuration.httpURL.scheme == "http")
        #expect(configuration.httpsURL.scheme == "https")
        #expect(configuration.httpsURL.host() == "zsk.labs.def.dev")
    }

    @Test
    func rejectsWrongHTTPScheme() {
        #expect(throws: LabConfigurationError.invalidHTTPSURL) {
            try LabConfiguration.parse([
                "LabHTTPURL": "http://zsk.labs.def.dev/pinning/success",
                "LabHTTPSURL": "http://zsk.labs.def.dev/pinning/success",
            ])
        }
    }
}

@MainActor
@Suite
struct ContentViewModelTests {
    @Test
    func osStoreScenarioUsesConfiguredHTTPSURL() async {
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
        #expect(viewModel.requestURL == configuration.httpsURL.absoluteString)
        #expect(viewModel.requestProgress == "response")
        #expect(requests == [configuration.httpsURL])
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