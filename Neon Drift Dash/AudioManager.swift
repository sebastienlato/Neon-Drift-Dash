import Foundation

enum SoundEffect {
    case start
    case collect
    case hit
    case gameOver
    case unlock
    case tap
}

final class AudioManager {
    static let shared = AudioManager()

    private init() {}

    func play(_ effect: SoundEffect, enabled: Bool) {
        guard enabled else { return }
        // Sound files can be dropped into the bundle later and routed from here.
    }
}
