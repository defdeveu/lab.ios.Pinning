import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel = ContentViewModel()
    
    var body: some View {
        ScrollView {
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
                Spacer()
                resultView()
                Spacer()
            }
            .padding()
        }
        .navigationTitle("lab.ios.Pinning")
    }
    
    @ViewBuilder private func scenarioButton(_ title: String,
                                             action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(SolidButtonStyle())
            .disabled(viewModel.isLoading)
    }
    
    @ViewBuilder private func resultView() -> some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 10) {
                Text("Retrieved URL:")
                    .font(.title3)
                    .foregroundColor(AppColors.textTitle)
                Text(viewModel.requestUrl ?? "-")
                Text("Retrieved content:")
                    .font(.title3)
                    .foregroundColor(AppColors.textTitle)
                Text(viewModel.requestProgress ?? "-")
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
