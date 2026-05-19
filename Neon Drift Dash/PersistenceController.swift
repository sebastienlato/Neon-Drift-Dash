import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    enum Key {
        static let highScore = "neonDriftDash.highScore"
        static let selectedBoard = "neonDriftDash.selectedBoard"
        static let soundEnabled = "neonDriftDash.soundEnabled"
        static let hapticsEnabled = "neonDriftDash.hapticsEnabled"
    }

    func integer(for key: String) -> Int {
        defaults.integer(forKey: key)
    }

    func string(for key: String) -> String? {
        defaults.string(forKey: key)
    }

    func bool(for key: String, default defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }

    func set(_ value: Int, for key: String) {
        defaults.set(value, forKey: key)
    }

    func set(_ value: String, for key: String) {
        defaults.set(value, forKey: key)
    }

    func set(_ value: Bool, for key: String) {
        defaults.set(value, forKey: key)
    }
}
