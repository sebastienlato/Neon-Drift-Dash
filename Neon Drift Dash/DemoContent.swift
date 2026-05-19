#if DEBUG
import SwiftUI

enum DemoContent {
    static func gameState(
        highScore: Int = 18_400,
        selectedBoard: BoardStyle = .phantom,
        lastUnlock: BoardStyle? = .solar
    ) -> GameState {
        let suiteName = "neonDriftDash.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(highScore, forKey: PersistenceController.Key.highScore)
        defaults.set(selectedBoard.rawValue, forKey: PersistenceController.Key.selectedBoard)

        let state = GameState(persistence: PersistenceController(defaults: defaults))
        if let lastUnlock {
            state.lastRunSummary = RunSummary(
                score: highScore,
                bestScore: highScore,
                shards: 42,
                bestCombo: 9,
                wave: 5,
                unlockedBoard: lastUnlock
            )
        }
        return state
    }

    static func lockedProgressState() -> GameState {
        gameState(highScore: 6_200, selectedBoard: .nova, lastUnlock: nil)
    }

    static func settings() -> GameSettings {
        let suiteName = "neonDriftDash.preview.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(true, forKey: PersistenceController.Key.soundEnabled)
        defaults.set(true, forKey: PersistenceController.Key.hapticsEnabled)
        return GameSettings(persistence: PersistenceController(defaults: defaults))
    }

    static let activeRunStats = RunStats(
        score: 8_760,
        shards: 34,
        combo: 6,
        bestCombo: 8,
        shields: 2,
        wave: 4,
        waveTitle: "Wave 4: Neon Storm",
        isGameOver: false
    )

    static let gameOverSummary = RunSummary(
        score: 15_420,
        bestScore: 18_400,
        shards: 58,
        bestCombo: 10,
        wave: 5,
        unlockedBoard: .solar
    )
}

#Preview("Home - Demo Ready") {
    HomeView(screen: .constant(.home))
        .environmentObject(DemoContent.gameState())
        .environmentObject(DemoContent.settings())
}

#Preview("Boards - Progression") {
    BoardsView(screen: .constant(.boards))
        .environmentObject(DemoContent.lockedProgressState())
        .environmentObject(DemoContent.settings())
}

#Preview("Gameplay HUD") {
    ZStack {
        NeonAnimatedBackground()
        VStack {
            GameHUD(stats: DemoContent.activeRunStats) {}
                .padding()
            Spacer()
        }
    }
}

#Preview("Game Over - Unlock") {
    GameOverOverlay(summary: DemoContent.gameOverSummary, restart: {}, home: {})
}

#Preview("Pause Overlay") {
    PauseOverlay(resume: {}, restart: {}, home: {})
}
#endif
