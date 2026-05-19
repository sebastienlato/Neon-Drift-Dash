import SwiftUI

struct BoardsView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var settings: GameSettings
    @Binding var screen: AppScreen

    var body: some View {
        ZStack {
            NeonAnimatedBackground(showRooftop: false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HeaderBar(title: "Boards", subtitle: "Unlock deck styles with bigger runs") {
                        screen = .home
                    }
                    .padding(.top, 18)

                    ForEach(BoardStyle.allCases) { board in
                        boardCard(board)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
    }

    private func boardCard(_ board: BoardStyle) -> some View {
        let unlocked = gameState.isUnlocked(board)
        let selected = gameState.selectedBoardStyle == board

        return GlassCard {
            HStack(spacing: 16) {
                BoardPreview(board: board, locked: !unlocked)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(board.displayName)
                            .font(.system(.headline, design: .rounded, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        if selected {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(DesignSystem.mint)
                        }
                    }

                    Text(board.subtitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.64))

                    if unlocked {
                        Button(selected ? "Selected" : "Select") {
                            gameState.select(board)
                            HapticsManager.shared.play(.tap, enabled: settings.hapticsEnabled)
                        }
                        .buttonStyle(BoardSelectButtonStyle(tint: board.primaryColor, selected: selected))
                        .disabled(selected)
                    } else {
                        ProgressView(value: min(Double(gameState.highScore), Double(board.unlockScore)), total: Double(board.unlockScore))
                            .tint(board.primaryColor)
                        Text("Unlocks at \(board.unlockScore) best score")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct BoardSelectButtonStyle: ButtonStyle {
    let tint: Color
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(selected ? DesignSystem.mint.opacity(0.45) : tint.opacity(configuration.isPressed ? 0.58 : 0.82), in: Capsule())
            .overlay {
                Capsule().stroke(.white.opacity(0.35), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
