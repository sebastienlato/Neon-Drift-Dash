import AVFoundation
import Foundation

enum SoundEffect: Hashable {
    case start
    case collect
    case comboIncrease
    case hit
    case shieldBreak
    case gameOver
    case unlock
    case tap
    case waveStart

    // Drop polished SFX into the app bundle with one of the supported extensions:
    // .caf, .wav, .mp3, or .m4a. Missing files intentionally play silence.
    var assetBaseName: String {
        switch self {
        case .tap: "sfx_tap"
        case .start: "sfx_start_run"
        case .collect: "sfx_shard_collect"
        case .comboIncrease: "sfx_combo_increase"
        case .hit: "sfx_player_hit"
        case .shieldBreak: "sfx_shield_break"
        case .unlock: "sfx_board_unlock"
        case .gameOver: "sfx_game_over"
        case .waveStart: "sfx_wave_start"
        }
    }
}

final class AudioManager {
    static let shared = AudioManager()

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private let supportedExtensions = ["caf", "wav", "mp3", "m4a"]

    private init() {
        AVAudioSession.sharedInstance().configureForNeonDriftDash()
    }

    func play(_ effect: SoundEffect, enabled: Bool) {
        guard enabled else { return }
        guard let player = player(for: effect) else { return }
        player.currentTime = 0
        player.play()
    }

    func prepareAll() {
        SoundEffect.allCasesForPreload.forEach { _ = player(for: $0) }
    }

    private func player(for effect: SoundEffect) -> AVAudioPlayer? {
        if let existing = players[effect] {
            return existing
        }

        guard let url = supportedExtensions.compactMap({ Bundle.main.url(forResource: effect.assetBaseName, withExtension: $0) }).first else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[effect] = player
            return player
        } catch {
            return nil
        }
    }
}

private extension SoundEffect {
    static let allCasesForPreload: [SoundEffect] = [
        .tap,
        .start,
        .collect,
        .comboIncrease,
        .hit,
        .shieldBreak,
        .unlock,
        .gameOver,
        .waveStart
    ]
}

private extension AVAudioSession {
    func configureForNeonDriftDash() {
        do {
            try setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try setActive(false, options: [])
        } catch {
            // Missing or unavailable audio session setup should never block gameplay.
        }
    }
}
