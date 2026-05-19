import SwiftUI

enum AppScreen {
    case home
    case game
    case boards
    case settings
    case howToPlay
}

struct GameRootView: View {
    @State private var screen: AppScreen = .home

    var body: some View {
        ZStack {
            switch screen {
            case .home:
                HomeView(screen: $screen)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .game:
                GameView(screen: $screen)
                    .transition(.opacity)
            case .boards:
                BoardsView(screen: $screen)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .settings:
                SettingsView(screen: $screen)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .howToPlay:
                HowToPlayView(screen: $screen)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: screen)
    }
}
