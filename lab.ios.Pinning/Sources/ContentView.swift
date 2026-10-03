import SwiftUI

struct ContentView: View {
    @State private var viewModel: ContentViewModel

    @MainActor
    init(viewModel: ContentViewModel = AppRepository.makeViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                introduction
                pinnedSet
                connect
                result
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(24)
        }
        .navigationTitle(AppStrings.appTitle)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image(.logoDddStamp1905)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
                    .accessibilityHidden(true)
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pinned by the platform")
                .font(.title2.bold())
            Text("Transport security is narrowed in Info.plist: the system accepts a connection to \(viewModel.checkedAgainstHost) only when the chain it presents contains one of the configured authority keys.")
                .foregroundStyle(.secondary)
            Text("This branch asks for HTTP/3 and uses the server's HTTP/3-only route; a request that falls back to TCP is refused with status 505.")
                .foregroundStyle(.secondary)
        }
    }

    private var pinnedSet: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pinned CA identities")
                .font(.headline)
            if viewModel.checkedAgainstDigests.isEmpty {
                Text("No pinned set is configured.")
                    .font(.body.monospaced())
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.checkedAgainstDigests, id: \.self) { digest in
                    Text(digest)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Text("The system matches these digests against the certificates in the chain the server presents; further entries act as backups.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var connect: some View {
        Button {
            viewModel.connect()
        } label: {
            Label(viewModel.isConnecting ? "Connecting…" : "Connect", systemImage: "network")
        }
        .buttonStyle(SolidButtonStyle())
        .disabled(viewModel.isConnecting)
    }

    private var result: some View {
        GroupBox("Last attempt") {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.result ?? "Not run yet")
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let protocolName = viewModel.negotiatedProtocol {
                    Text("Protocol: \(protocolName)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
