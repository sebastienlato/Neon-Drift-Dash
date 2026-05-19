import Foundation
import Combine

struct RunStats: Equatable {
    var score: Int
    var shards: Int
    var combo: Int
    var bestCombo: Int
    var shields: Int
    var wave: Int
    var waveTitle: String
    var isGameOver: Bool

    static let empty = RunStats(
        score: 0,
        shards: 0,
        combo: 1,
        bestCombo: 1,
        shields: 3,
        wave: 1,
        waveTitle: "Wave 1: Rooftop Run",
        isGameOver: false
    )
}

struct RunSummary: Equatable {
    let score: Int
    let bestScore: Int
    let shards: Int
    let bestCombo: Int
    let wave: Int
    let unlockedBoard: BoardStyle?
}

final class GameState: ObservableObject {
    @Published private(set) var highScore: Int
    @Published var selectedBoardID: String {
        didSet { persistence.set(selectedBoardID, for: PersistenceController.Key.selectedBoard) }
    }
    @Published var lastRunSummary: RunSummary?

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        highScore = persistence.integer(for: PersistenceController.Key.highScore)
        selectedBoardID = persistence.string(for: PersistenceController.Key.selectedBoard) ?? BoardStyle.pulse.rawValue
        if selectedBoard == nil {
            selectedBoardID = BoardStyle.pulse.rawValue
        }
    }

    var selectedBoard: BoardStyle? {
        guard let board = BoardStyle(rawValue: selectedBoardID), board.isUnlocked(highScore: highScore) else {
            return .pulse
        }
        return board
    }

    var selectedBoardStyle: BoardStyle {
        selectedBoard ?? .pulse
    }

    func isUnlocked(_ board: BoardStyle) -> Bool {
        board.isUnlocked(highScore: highScore)
    }

    func select(_ board: BoardStyle) {
        guard isUnlocked(board) else { return }
        selectedBoardID = board.rawValue
    }

    @discardableResult
    func finishRun(score: Int, shards: Int, bestCombo: Int, wave: Int) -> RunSummary {
        let previousHighScore = highScore
        let previouslyUnlocked = Set(BoardStyle.allCases.filter { $0.isUnlocked(highScore: previousHighScore) })

        if score > highScore {
            highScore = score
            persistence.set(highScore, for: PersistenceController.Key.highScore)
        }

        let newlyUnlocked = BoardStyle.allCases.first { board in
            !previouslyUnlocked.contains(board) && board.isUnlocked(highScore: highScore)
        }

        let summary = RunSummary(
            score: score,
            bestScore: highScore,
            shards: shards,
            bestCombo: bestCombo,
            wave: wave,
            unlockedBoard: newlyUnlocked
        )
        lastRunSummary = summary
        return summary
    }

    func resetHighScore() {
        highScore = 0
        persistence.set(0, for: PersistenceController.Key.highScore)
        if selectedBoardStyle != .pulse {
            selectedBoardID = BoardStyle.pulse.rawValue
        }
        lastRunSummary = nil
    }
}
