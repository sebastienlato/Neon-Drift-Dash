import Foundation
import Combine

final class GameSettings: ObservableObject {
    @Published var soundEnabled: Bool {
        didSet { persistence.set(soundEnabled, for: PersistenceController.Key.soundEnabled) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { persistence.set(hapticsEnabled, for: PersistenceController.Key.hapticsEnabled) }
    }

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        soundEnabled = persistence.bool(for: PersistenceController.Key.soundEnabled, default: true)
        hapticsEnabled = persistence.bool(for: PersistenceController.Key.hapticsEnabled, default: true)
    }
}
