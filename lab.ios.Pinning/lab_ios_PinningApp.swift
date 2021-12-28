import SwiftUI

@main
struct lab_ios_PinningApp: App {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.navigationBackground)
        appearance.backgroundImage = UIImage(named: "bg-banner.ddd.2108.dark")

        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(AppColors.navigationForeground)
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
            .navigationViewStyle(.stack)
            .preferredColorScheme(.dark)
        }
    }
}
