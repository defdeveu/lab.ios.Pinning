import SwiftUI

@main
struct lab_ios_PinningApp: App {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.navigationBackground

        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: AppColors.navigationForeground
        ]

        appearance.largeTitleTextAttributes = attrs
        appearance.titleTextAttributes = attrs

        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
