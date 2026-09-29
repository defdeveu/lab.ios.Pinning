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
                leafPin
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
            Text("Leaf pin, and what breaks it")
                .font(.title2.bold())
            Text("This app trusts one leaf key. Change the effective pin and watch what the pinned connection does.")
                .foregroundStyle(.secondary)
        }
    }

    private var leafPin: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Effective leaf pin")
                .font(.headline)
            Text(viewModel.effectiveLeafPin)
                .font(.body.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Effective leaf pin")
            HStack(spacing: 12) {
                actionButton(
                    title: "Break the pin",
                    systemImage: "scissors",
                    action: viewModel.breakLeafPin
                )
                actionButton(
                    title: "Restore",
                    systemImage: "arrow.uturn.backward",
                    action: viewModel.restoreLeafPin
                )
            }
            Text("Break rewrites part of the stored pin. From the comparison's point of view that is the same as the server presenting a different certificate.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var connect: some View {
        actionButton(
            title: viewModel.isConnecting ? "Connecting…" : "Connect",
            systemImage: "network",
            action: viewModel.connect,
            disabled: viewModel.isConnecting
        )
    }

    private var result: some View {
        GroupBox("Last attempt") {
            Text(viewModel.result ?? "Not run yet")
                .font(.body.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .contain)
    }

    private func actionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void,
        disabled: Bool = false
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(SolidButtonStyle())
        .disabled(disabled)
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
