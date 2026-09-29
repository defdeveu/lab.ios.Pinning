import Foundation
import Testing
@testable import lab_ios_Pinning

private let hostedURL = "https://zsk.labs.def.dev/pinning/success"
private let primaryPin = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
private let backupPin = "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE="

private func hostedValues(identities: [[String: Any]]) -> [String: Any] {
    [
        "LabPinningURL": hostedURL,
        "NSAppTransportSecurity": [
            "NSPinnedDomains": [
                "zsk.labs.def.dev": [
                    "NSPinnedCAIdentities": identities,
                ],
            ],
        ],
    ]
}

@Suite
struct LabConfigurationTests {
    @Test
    func parsesThePinnedSetFromThePlistShape() throws {
        let configuration = try LabConfiguration.parse(hostedValues(identities: [
            ["SPKI-SHA256-BASE64": primaryPin],
            ["SPKI-SHA256-BASE64": backupPin],
        ]))

        #expect(configuration.pinnedHost == "zsk.labs.def.dev")
        #expect(configuration.pinnedIdentity?.digests == [primaryPin, backupPin])
    }

    @Test
    func rejectsANonHTTPSPinningURL() {
        var values = hostedValues(identities: [["SPKI-SHA256-BASE64": primaryPin]])
        values["LabPinningURL"] = "http://zsk.labs.def.dev/pinning/success"
        #expect(throws: LabConfigurationError.invalidPinningURL) {
            try LabConfiguration.parse(values)
        }
    }

    @Test
    func rejectsAMissingEntryForTheHost() {
        let values: [String: Any] = [
            "LabPinningURL": hostedURL,
            "NSAppTransportSecurity": [
                "NSPinnedDomains": [
                    "example.test": ["NSPinnedCAIdentities": [["SPKI-SHA256-BASE64": primaryPin]]],
                ],
            ],
        ]
        #expect(throws: LabConfigurationError.missingPinnedIdentity("zsk.labs.def.dev")) {
            try LabConfiguration.parse(values)
        }
    }

    @Test
    func rejectsAnEmptyIdentityArray() {
        #expect(throws: LabConfigurationError.missingPinnedIdentity("zsk.labs.def.dev")) {
            try LabConfiguration.parse(hostedValues(identities: []))
        }
    }
}

@MainActor
@Suite
struct ContentViewModelTests {
    @Test
    func connectShowsTheResponseAndListsThePinnedSet() async throws {
        let viewModel = try makeViewModel(client: StubNetworkService { _ in
            Data("Connection succeeded.".utf8)
        })

        viewModel.connect()
        while viewModel.isConnecting {
            await Task.yield()
        }

        #expect(viewModel.result == "Connection succeeded.")
        #expect(viewModel.checkedAgainstHost == "zsk.labs.def.dev")
        #expect(viewModel.checkedAgainstDigests == ["sha256/\(primaryPin)", "sha256/\(backupPin)"])
    }

    @Test
    func connectShowsThePlatformFailure() async throws {
        let viewModel = try makeViewModel(client: StubNetworkService { _ in
            throw URLError(.serverCertificateUntrusted)
        })

        viewModel.connect()
        while viewModel.isConnecting {
            await Task.yield()
        }

        #expect(viewModel.result?.isEmpty == false)
    }

    private func makeViewModel(client: any NetworkServiceProtocol) throws -> ContentViewModel {
        ContentViewModel(
            configuration: try LabConfiguration.parse(hostedValues(identities: [
                ["SPKI-SHA256-BASE64": primaryPin],
                ["SPKI-SHA256-BASE64": backupPin],
            ])),
            networkService: client
        )
    }
}

private struct StubNetworkService: NetworkServiceProtocol {
    let handler: @Sendable (URLRequest) async throws -> Data

    func process(request: URLRequest) async throws -> Data {
        try await handler(request)
    }
}
