import SwiftUI
import SpriteKit

enum BoardStyle: String, CaseIterable, Identifiable {
    case pulse
    case nova
    case phantom
    case solar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pulse: "Pulse Board"
        case .nova: "Nova Board"
        case .phantom: "Phantom Board"
        case .solar: "Solar Board"
        }
    }

    var shortName: String {
        switch self {
        case .pulse: "Pulse"
        case .nova: "Nova"
        case .phantom: "Phantom"
        case .solar: "Solar"
        }
    }

    var subtitle: String {
        switch self {
        case .pulse: "Balanced glow"
        case .nova: "Hot streak trails"
        case .phantom: "Violet phase edge"
        case .solar: "Orange starburst deck"
        }
    }

    var unlockScore: Int {
        switch self {
        case .pulse: 0
        case .nova: 2_000
        case .phantom: 6_000
        case .solar: 12_000
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var colors: [Color] {
        switch self {
        case .pulse:
            [DesignSystem.cyan, DesignSystem.magenta]
        case .nova:
            [DesignSystem.orange, DesignSystem.magenta]
        case .phantom:
            [DesignSystem.violet, DesignSystem.cyan]
        case .solar:
            [DesignSystem.orange, DesignSystem.gold]
        }
    }

    var primaryColor: Color {
        colors.first ?? DesignSystem.cyan
    }

    var skPrimaryColor: SKColor {
        switch self {
        case .pulse: SKColor(red: 0.11, green: 0.82, blue: 1.0, alpha: 1)
        case .nova: SKColor(red: 1.0, green: 0.32, blue: 0.14, alpha: 1)
        case .phantom: SKColor(red: 0.55, green: 0.18, blue: 1.0, alpha: 1)
        case .solar: SKColor(red: 1.0, green: 0.68, blue: 0.18, alpha: 1)
        }
    }

    var skSecondaryColor: SKColor {
        switch self {
        case .pulse: SKColor(red: 1.0, green: 0.1, blue: 0.78, alpha: 1)
        case .nova: SKColor(red: 0.58, green: 0.12, blue: 1.0, alpha: 1)
        case .phantom: SKColor(red: 0.0, green: 0.86, blue: 1.0, alpha: 1)
        case .solar: SKColor(red: 1.0, green: 0.18, blue: 0.43, alpha: 1)
        }
    }

    func isUnlocked(highScore: Int) -> Bool {
        highScore >= unlockScore
    }
}
