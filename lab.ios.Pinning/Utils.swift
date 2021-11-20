import SwiftUI

// MARK: - Button style

struct SolidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .frame(minHeight: 48)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
        }
        .foregroundColor(AppColors.button)
        .font(.headline)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.button, lineWidth: 2)
        )
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .padding([.top, .bottom], 8)
    }
}

// MARK: - Colors

struct AppColors {
    private init() {}
    
    static let navigationBackground = UIColor(named: "NavigationBkgdColor") ?? .black
    static let navigationForeground = UIColor(named: "NavigationFrgdColor") ?? .white
    static let button = Color(UIColor(named: "ButtonColor") ?? .black)
    static let textTitle = Color(UIColor(named: "TextTitleColor") ?? .black)
}

// MARK: - Application Services

final class AppRepository {
    static var shared = AppRepository()
    private init() { }
    
    private lazy var sessionPinningDelegate: URLSessionDelegate = SessionPinningDelegate()
    
    lazy var networkService: NetworkServiceProtocol = {
        let session = URLSession(
                    configuration: URLSessionConfiguration.ephemeral,
                    delegate: sessionPinningDelegate,
                    delegateQueue: nil)
        return NetworkService(session: session)
    }()
}
