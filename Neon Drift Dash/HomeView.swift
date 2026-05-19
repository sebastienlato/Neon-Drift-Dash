import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var settings: GameSettings
    @Binding var screen: AppScreen
    @State private var pulse = false
    @State private var calloutPulse = false

    var body: some View {
        ZStack {
            NeonAnimatedBackground()

            VStack(spacing: 16) {
                Spacer(minLength: 12)

                logo
                    .padding(.horizontal, 22)
                    .scaleEffect(pulse ? 1.015 : 0.985)
                    .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: pulse)

                GlassCard {
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            StatPill(title: "Best Run", value: "\(gameState.highScore)", tint: DesignSystem.gold)
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(gameState.selectedBoardStyle.displayName)
                                    .font(.system(.headline, design: .rounded, weight: .black))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("Ready for shard rush")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.62))
                            }
                            BoardPreview(board: gameState.selectedBoardStyle, selected: true)
                                .frame(width: 118)
                        }

                        if let unlocked = gameState.lastRunSummary?.unlockedBoard {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(DesignSystem.gold)
                                Text("\(unlocked.shortName) is live in Boards")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(DesignSystem.gold.opacity(calloutPulse ? 0.24 : 0.13), in: Capsule())
                            .overlay {
                                Capsule().stroke(DesignSystem.gold.opacity(0.42), lineWidth: 1)
                            }
                            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: calloutPulse)
                        }
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

                Text("Rooftop pulse • drag to drift • chase the streak")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.top, 6)

                Spacer(minLength: 18)
            }
        }
        .onAppear {
            pulse = true
            calloutPulse = true
        }
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
