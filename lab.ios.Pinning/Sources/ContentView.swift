import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel = ContentViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                menu()

                resultView()

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { appTitle() }
    }

    @ViewBuilder
    private func menu() -> some View {
        VStack(spacing: 10) {
            scenarioButton("Use pinned certificate") {
                viewModel.pinnedCertificateConnection()
            }
            scenarioButton("Use OS CA store") {
                viewModel.osStoreConnection()
            }
            scenarioButton("Use plain HTTP channel") {
                viewModel.plainTextConnection()
            }
        }
    }

    @ToolbarContentBuilder
    private func appTitle() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack {
                AppImages.appTitleImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .colorInvert()
                // TODO colorInvert as per the scheme
                Text(AppStrings.appTitle)
                    .font(.title.bold())
                    .foregroundColor(AppColors.navigationForeground)
            }
            .padding(.bottom, 8)
        }
    }
    
    @ViewBuilder
    private func scenarioButton(_ title: String,
                                action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(SolidButtonStyle())
            .disabled(viewModel.isLoading)
    }
    
    @ViewBuilder
    private func resultView() -> some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 10) {
                resultViewItem(title: "Retrieved URL:",
                               value: viewModel.requestUrl)

                resultViewItem(title: "Retrieved content:",
                               value: viewModel.requestProgress)
            }
        }
    }

    @ViewBuilder
    private func resultViewItem(title: String, value: String?) -> some View {
        Text(title)
            .font(.title3)
            .foregroundColor(AppColors.textTitle)
            .fixedSize(horizontal: false, vertical: true)
        Text(value ?? "-")
            .foregroundColor(AppColors.textOutput)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
