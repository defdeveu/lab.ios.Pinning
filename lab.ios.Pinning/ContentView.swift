import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel = ContentViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10.0) {
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
            .preferredColorScheme(.dark)
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { appToolBar() }
        // .navigationTitle("Pinning lab".uppercased())
    }
    

    private func appToolBar() -> some ToolbarContent {
        
        ToolbarItem(placement: .navigationBarLeading) {
            HStack {
                Image("logo.ddd.stamp.1905").resizable().aspectRatio(contentMode: .fit).colorInvert()
                    // TODO colorInvert as per the scheme
                Text("Pinning lab".uppercased())
                    .font(.title.bold())
                    .foregroundColor(AppColors.navigationForeground)
            }
        }
        
        // TODO Please add bottom padding wo breaking the above inline image fitting the title line
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
                    .fixedSize(horizontal: false, vertical: true)
                Text(viewModel.requestUrl ?? "-")
                    .foregroundColor(AppColors.textOutput)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Retrieved content:")
                    .font(.title3)
                    .foregroundColor(AppColors.textTitle)
                    .fixedSize(horizontal: false, vertical: true)
                Text(viewModel.requestProgress ?? "-")
                    .foregroundColor(AppColors.textOutput)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
