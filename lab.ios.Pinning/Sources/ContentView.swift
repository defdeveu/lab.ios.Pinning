import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel

    @MainActor
    init(viewModel: ContentViewModel = AppRepository.makeViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                introduction
                scenarios
                result
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(24)
        }
        .navigationTitle(AppStrings.appTitle)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                AppImages.appTitleImage
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
            Text("Compare three transport-security choices")
                .font(.title2.bold())
            Text("Run each request and inspect which trust decision succeeds. The pinned request should accept only the configured server key.")
                .foregroundStyle(.secondary)
        }
    }

    private var scenarios: some View {
        VStack(spacing: 12) {
            scenarioButton(
                title: "Use pinned public key",
                systemImage: "checkmark.shield",
                action: viewModel.pinnedCertificateConnection
            )
            scenarioButton(
                title: "Use OS CA store",
                systemImage: "network.badge.shield.half.filled",
                action: viewModel.osStoreConnection
            )
            scenarioButton(
                title: "Use plain HTTP channel",
                systemImage: "lock.open",
                action: viewModel.plainTextConnection
            )
        }
    }

    private var result: some View {
        GroupBox("Request result") {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Connecting…")
                }
                resultItem(title: "URL", value: viewModel.requestURL)
                resultItem(title: "Response", value: viewModel.requestProgress)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
        .accessibilityElement(children: .contain)
    }

    private func scenarioButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(SolidButtonStyle())
        .disabled(viewModel.isLoading)
        .accessibilityHint("Runs this connection scenario")
    }

    private func resultItem(title: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value ?? "Not run yet")
                .font(.body.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView()
        }
    }
}
