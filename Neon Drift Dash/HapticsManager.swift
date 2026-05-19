import UIKit

enum HapticEvent {
    case start
    case collect
    case hit
    case gameOver
    case unlock
    case tap
}

final class HapticsManager {
    static let shared = HapticsManager()

    private init() {}

    func play(_ event: HapticEvent, enabled: Bool) {
        guard enabled else { return }

        switch event {
        case .start, .tap:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .collect:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .hit:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .gameOver:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .unlock:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
