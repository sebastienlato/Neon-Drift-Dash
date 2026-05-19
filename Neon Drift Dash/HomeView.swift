import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var settings: GameSettings
    @Binding var screen: AppScreen
    @State private var pulse = false

    var body: some View {
        ZStack {
            NeonAnimatedBackground()

            VStack(spacing: 18) {
                Spacer(minLength: 16)

                logo
                    .padding(.horizontal, 22)
                    .scaleEffect(pulse ? 1.015 : 0.985)
                    .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: pulse)

                GlassCard {
                    HStack(spacing: 14) {
                        StatPill(title: "Best", value: "\(gameState.highScore)", tint: DesignSystem.gold)
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(gameState.selectedBoardStyle.displayName)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("Selected board")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.62))
                        }
                        BoardPreview(board: gameState.selectedBoardStyle)
                            .frame(width: 118)
                    }
                }
                .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    NeonButton(title: "Start Run", systemImage: "play.fill") {
                        tapped(.start)
                        screen = .game
                    }

                    HStack(spacing: 12) {
                        squareNavButton("Boards", icon: "sparkles") {
                            tapped(.tap)
                            screen = .boards
                        }
                        squareNavButton("How", icon: "questionmark.circle.fill") {
                            tapped(.tap)
                            screen = .howToPlay
                        }
                        squareNavButton("Settings", icon: "slider.horizontal.3") {
                            tapped(.tap)
                            screen = .settings
                        }
                    }
                }
                .padding(.horizontal, 20)

                Text("Tap to Drift")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.top, 6)

                Spacer(minLength: 18)
            }
        }
        .onAppear { pulse = true }
    }

    @ViewBuilder
    private var logo: some View {
        if DesignSystem.assetExists("LogoNeonDriftDash") {
            Image("LogoNeonDriftDash")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 210)
                .shadow(color: DesignSystem.magenta.opacity(0.38), radius: 24)
                .shadow(color: DesignSystem.cyan.opacity(0.28), radius: 18)
        } else {
            VStack(spacing: 0) {
                Text("NEON")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(DesignSystem.neonGradient)
                Text("DRIFT DASH")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: DesignSystem.magenta.opacity(0.6), radius: 16)
        }
    }

    private func squareNavButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(.ultraThinMaterial.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(DesignSystem.cyan.opacity(0.36), lineWidth: 1)
            }
        }
        .buttonStyle(NeonPressButtonStyle())
    }

    private func tapped(_ event: HapticEvent) {
        HapticsManager.shared.play(event, enabled: settings.hapticsEnabled)
        AudioManager.shared.play(.tap, enabled: settings.soundEnabled)
    }
}
