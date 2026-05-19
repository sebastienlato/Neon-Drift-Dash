import SpriteKit
import SwiftUI

struct GameView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var settings: GameSettings
    @Binding var screen: AppScreen

    @State private var scene: GameScene?
    @State private var stats = RunStats.empty
    @State private var summary: RunSummary?
    @State private var isPaused = false
    @State private var viewSize = CGSize.zero

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let scene {
                    SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                        .ignoresSafeArea()
                } else {
                    NeonAnimatedBackground()
                }

                VStack(spacing: 0) {
                    GameHUD(stats: stats, pauseAction: togglePause)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                    Spacer()
                }

                if isPaused {
                    PauseOverlay(
                        resume: togglePause,
                        restart: restart,
                        home: goHome
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                if stats.isGameOver, let summary {
                    GameOverOverlay(
                        summary: summary,
                        restart: restart,
                        home: goHome
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }
            .onAppear {
                viewSize = proxy.size
                createSceneIfNeeded(size: proxy.size)
            }
            .onChange(of: proxy.size) { _, newSize in
                viewSize = newSize
                scene?.size = newSize
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isPaused)
        .animation(.spring(response: 0.36, dampingFraction: 0.84), value: stats.isGameOver)
        .onDisappear {
            scene?.shutdown()
            scene = nil
        }
    }

    private func createSceneIfNeeded(size: CGSize) {
        guard scene == nil else { return }
        startNewScene(size: size)
    }

    private func startNewScene(size: CGSize? = nil) {
        let sceneSize = size ?? (viewSize == .zero ? CGSize(width: 393, height: 852) : viewSize)
        let newScene = GameScene(
            size: sceneSize,
            boardStyle: gameState.selectedBoardStyle,
            settings: settings,
            gameState: gameState
        )
        newScene.onStatsChanged = { incoming in
            DispatchQueue.main.async {
                stats = incoming
            }
        }
        newScene.onGameOver = { incoming in
            DispatchQueue.main.async {
                summary = incoming
            }
        }
        scene = newScene
        stats = .empty
        summary = nil
        isPaused = false
    }

    private func togglePause() {
        guard !stats.isGameOver else { return }
        isPaused.toggle()
        scene?.isPaused = isPaused
        HapticsManager.shared.play(.tap, enabled: settings.hapticsEnabled)
    }

    private func restart() {
        scene?.shutdown()
        scene = nil
        startNewScene()
        HapticsManager.shared.play(.start, enabled: settings.hapticsEnabled)
    }

    private func goHome() {
        scene?.shutdown()
        scene = nil
        screen = .home
    }
}

struct GameHUD: View {
    let stats: RunStats
    let pauseAction: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                StatPill(title: "Score", value: "\(stats.score)", tint: DesignSystem.cyan)
                StatPill(title: "Combo", value: "x\(stats.combo)", tint: stats.combo > 1 ? DesignSystem.magenta : DesignSystem.violet)
                    .scaleEffect(stats.combo > 1 ? 1.06 : 1)
                    .shadow(color: stats.combo > 1 ? DesignSystem.magenta.opacity(0.35) : .clear, radius: 12)
                StatPill(title: "Shield", value: shieldText, tint: stats.shields <= 1 ? DesignSystem.orange : DesignSystem.mint)

                Button(action: pauseAction) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(DesignSystem.magenta.opacity(0.48), lineWidth: 1)
                        }
                }
                .buttonStyle(NeonPressButtonStyle())
                .disabled(stats.isGameOver)
            }

            HStack {
                Text(stats.waveTitle)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.65), in: Capsule())
                    .overlay {
                        Capsule().stroke(DesignSystem.orange.opacity(0.38), lineWidth: 1)
                    }

                Spacer(minLength: 10)

                Text("Shards \(stats.shards)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(DesignSystem.cyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.65), in: Capsule())
            }
        }
    }

    private var shieldText: String {
        stats.shields > 0 ? String(repeating: "◆", count: stats.shields) : "0"
    }
}

struct PauseOverlay: View {
    let resume: () -> Void
    let restart: () -> Void
    let home: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.46)
                .ignoresSafeArea()

            GlassCard {
                VStack(spacing: 16) {
                    Text("Paused")
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .foregroundStyle(.white)

                    Text("Hold the pulse. Pick your line.")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))

                    NeonButton(title: "Resume Run", systemImage: "play.fill", action: resume)
                    NeonButton(title: "Restart Dash", systemImage: "arrow.clockwise", style: .secondary, action: restart)
                    NeonButton(title: "Home", systemImage: "house.fill", style: .secondary, action: home)
                }
            }
            .padding(.horizontal, 26)
        }
    }
}

struct GameOverOverlay: View {
    let summary: RunSummary
    let restart: () -> Void
    let home: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            GlassCard {
                VStack(spacing: 16) {
                    Text("Dash Over")
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .foregroundStyle(DesignSystem.neonGradient)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    if let unlocked = summary.unlockedBoard {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(DesignSystem.gold)
                            Text("\(unlocked.shortName) unlocked")
                                .font(.system(.headline, design: .rounded, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(DesignSystem.gold.opacity(0.16), in: Capsule())
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatPill(title: "Final", value: "\(summary.score)", tint: DesignSystem.cyan)
                        StatPill(title: "Best", value: "\(summary.bestScore)", tint: DesignSystem.gold)
                        StatPill(title: "Shards", value: "\(summary.shards)", tint: DesignSystem.magenta)
                        StatPill(title: "Best Combo", value: "x\(summary.bestCombo)", tint: DesignSystem.orange)
                    }

                    Text("Wave \(summary.wave) reached")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(.white.opacity(0.75))

                    NeonButton(title: "Run It Back", systemImage: "arrow.clockwise", action: restart)
                    NeonButton(title: "Home", systemImage: "house.fill", style: .secondary, action: home)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
