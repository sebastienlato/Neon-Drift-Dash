import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var settings: GameSettings
    @Binding var screen: AppScreen
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            NeonAnimatedBackground(showRooftop: false)

            VStack(spacing: 16) {
                HeaderBar(title: "Settings", subtitle: "Tune feedback and local progress") {
                    screen = .home
                }
                .padding(.top, 18)

                GlassCard {
                    VStack(spacing: 16) {
                        ToggleRow(title: "Sound Effects", subtitle: "Hooks are ready for bundled SFX", icon: "speaker.wave.2.fill", tint: DesignSystem.cyan, isOn: $settings.soundEnabled)
                        Divider().overlay(.white.opacity(0.12))
                        ToggleRow(title: "Haptics", subtitle: "Collect, hit, unlock, and game-over feedback", icon: "iphone.radiowaves.left.and.right", tint: DesignSystem.magenta, isOn: $settings.hapticsEnabled)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(DesignSystem.gold)
                            Text("Best score: \(gameState.highScore)")
                                .font(.system(.headline, design: .rounded, weight: .black))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        NeonButton(title: "Reset High Score", systemImage: "trash.fill", style: .danger) {
                            showResetConfirmation = true
                        }
                    }
                }

                Spacer()

                Text("Neon Drift Dash v1.0\nBuilt with SwiftUI, SpriteKit, generated art, and procedural fallbacks.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.48))
                    .padding(.bottom, 22)
            }
            .padding(.horizontal, 18)
        }
        .confirmationDialog("Reset high score?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset High Score", role: .destructive) {
                gameState.resetHighScore()
                HapticsManager.shared.play(.hit, enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Locked boards will lock again if their milestone is no longer met.")
        }
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.16))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tint)
        }
    }
}
