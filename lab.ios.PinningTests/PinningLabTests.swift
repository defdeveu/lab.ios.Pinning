import Foundation
import XCTest
@testable import lab_ios_Pinning

final class LabConfigurationTests: XCTestCase {
    func testParsesHostedValuesAndMultiplePins() throws {
        let first = "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        let second = "sha256/AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE="

        let configuration = try LabConfiguration.parse([
            "LabHTTPURL": "http://zsk.labs.def.dev/pinning/success",
            "LabHTTPSURL": "https://zsk.labs.def.dev/pinning/success",
            "LabSPKIPins": "\(first), \(second)",
        ])

        XCTAssertEqual(configuration.pinnedHost, "zsk.labs.def.dev")
        XCTAssertEqual(configuration.pins.count, 2)
    }

    func testRejectsMissingPins() {
        XCTAssertThrowsError(try LabConfiguration.parse([
            "LabHTTPURL": "http://zsk.labs.def.dev/pinning/success",
            "LabHTTPSURL": "https://zsk.labs.def.dev/pinning/success",
        ])) { error in
            XCTAssertEqual(error as? LabConfigurationError, .missingPins)
        }
    }
}

final class SPKIPinTests: XCTestCase {
    func testParsesAndFormatsSHA256Pin() throws {
        let value = "sha256/AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE="
        XCTAssertEqual(try SPKIPin(value).description, value)
    }

    func testRejectsWrongDigestLength() {
        XCTAssertThrowsError(try SPKIPin("sha256/AQ=="))
    }

    func testP256SPKIHashVector() throws {
        let rawPublicKey = Data([0x04] + Array(repeating: 0, count: 64))
        let pin = try SPKIHasher.pin(p256PublicKey: rawPublicKey)
        XCTAssertEqual(pin.description, "sha256/FhPubfxu6YoU7IG0Hq45pUOLUPvLv4oAgUflVyabRMs=")
    }
}

@MainActor
final class ContentViewModelTests: XCTestCase {
    func testPinnedScenarioUsesPinnedClientAndHTTPSURL() async {
        let systemClient = RecordingNetworkService(response: Data("system".utf8))
        let pinnedClient = RecordingNetworkService(response: Data("pinned".utf8))
        let configuration = LabConfiguration(
            httpURL: URL(string: "http://example.test/pinning/success")!,
            httpsURL: URL(string: "https://example.test/pinning/success")!,
            pins: []
        )
        let viewModel = ContentViewModel(
            configuration: configuration,
            systemClient: systemClient,
            pinnedClient: pinnedClient
        )

        viewModel.pinnedCertificateConnection()
        while viewModel.isLoading {
            await Task.yield()
        }

        XCTAssertEqual(viewModel.requestURL, configuration.httpsURL.absoluteString)
        XCTAssertEqual(viewModel.requestProgress, "pinned")
        let pinnedRequests = await pinnedClient.requestedURLs()
        let systemRequests = await systemClient.requestedURLs()
        XCTAssertEqual(pinnedRequests, [configuration.httpsURL])
        XCTAssertEqual(systemRequests, [])
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
