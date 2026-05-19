# Neon Drift Dash Release Checklist

## Build Verification

- Run `xcodebuild -project 'Neon Drift Dash.xcodeproj' -scheme 'Neon Drift Dash' -configuration Debug -destination 'generic/platform=iOS Simulator' build`.
- Run a Release configuration build before TestFlight.
- Confirm no missing asset warnings in Xcode.
- Confirm no runtime crashes when sound assets are absent.

## Device Testing

- Test on iPhone 15 or newer simulator/device.
- Test on a smaller iPhone viewport for HUD fit.
- Test pause, resume, restart, home return, and game over.
- Test board selection persistence after force quit/relaunch.
- Test high score persistence after force quit/relaunch.
- Test reset high score and confirm locked boards relock.
- Test haptics on physical device.

## Audio Files To Add Later

Add polished short SFX to the app bundle using any supported extension: `.caf`, `.wav`, `.mp3`, or `.m4a`.

- `sfx_tap`: crisp UI tap
- `sfx_start_run`: quick neon start pulse
- `sfx_shard_collect`: bright shard pickup
- `sfx_combo_increase`: rising combo hit
- `sfx_player_hit`: short impact glitch
- `sfx_shield_break`: heavier shield crack
- `sfx_board_unlock`: reward sparkle/stinger
- `sfx_game_over`: brief fail/downbeat sting
- `sfx_wave_start`: energetic wave transition

Keep sounds clean, modern, and non-childish. Avoid long loops until a music/mute design is added.

## Screenshot Checklist

- Home screen with logo and selected board visible.
- Active gameplay with score, combo, shields, and shards visible.
- Wave banner moment with hazards visible.
- Boards screen showing locked/unlocked progression.
- Game over screen with best score and unlock badge.
- Capture on a tall iPhone simulator.
- Check that captions do not cover key UI.

## App Icon Checklist

- Create a production App Icon using the neon hoverboard/logo style.
- Verify all required icon sizes in `AppIcon.appiconset`.
- Avoid tiny text in the icon.
- Test icon readability in light and dark Home Screen contexts.

## Privacy Checklist

- Confirm no third-party SDKs are added.
- Confirm no network calls are made.
- Confirm App Privacy answers match local-only storage.
- Add a privacy policy URL before App Store submission if required by account policy.

## TestFlight Checklist

- Increment build number.
- Archive from Xcode with Release configuration.
- Upload to App Store Connect.
- Add test notes explaining drag controls, board unlocks, and haptic/audio toggles.
- Test fresh install and upgrade install.

## App Store Connect Checklist

- Add app name, subtitle, keywords, description, support URL, and marketing URL.
- Add screenshots for required iPhone sizes.
- Add age rating answers.
- Add privacy nutrition labels.
- Add copyright and contact info.
- Confirm category: Games / Action or Arcade.

## Known Limitations

- Audio manager is ready for real SFX, but no sound files are bundled yet.
- There is no background music track.
- High score and cosmetics are local-only.
- No Game Center leaderboard is implemented.
- Board visuals are currently procedural UI previews plus the rider board art, not separate generated board sprites in gameplay.
