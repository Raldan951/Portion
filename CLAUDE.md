# CLAUDE.md — Portion
*Loads when this project is open in VSCode. Wiki is the source of truth for state, decisions, and architecture.*

## Current State
Build 44 — live on TestFlight (iOS + macOS).
**Next:** App Store listing, GitHub Pages (privacy policy + support URL), launch screen replacement.

Full state and open questions: `wiki/projects/Portion.md`

## Workspace
Always open: `/Volumes/OWC_Envoy_Ultra/Projects/BibleJournal-V2/Flutter-UI/`
Do NOT open the parent folder (BibleJournal-V2/) mid-session — it breaks the Claude Code session.

## Build Process
1. Bump `version` in `pubspec.yaml` (e.g. `1.0.0+45`)
2. Update `'build XX'` label in `home_screen.dart` to match
3. Run `flutter build macos --release` — keeps `Flutter-Generated.xcconfig` current
4. Xcode → `macos/Runner.xcworkspace` → Product → Archive → Distribute to App Store Connect
5. Xcode → `ios/Runner.xcworkspace` → Any iOS Device (arm64) → Product → Archive → Distribute to App Store Connect

## Platform References
- Bundle ID: `com.peterparise.portion` — Apple Team: `5Z3GFMWL86`
- iCloud container: `iCloud.com.peterparise.portion`
- Native channel: `ios/Runner/ICloudService.swift`, `macos/Runner/ICloudService.swift`

## Known Constraints
- iOS simulator requires Release scheme in Xcode (Flutter VSyncClient bug in debug on iOS 26.x — all available simulators are 26.x)
- `flutter run -d macos` unreliable — use Xcode directly for macOS builds

## iOS Simulator Testing
1. Open `ios/Runner.xcworkspace` in Xcode
2. Edit Scheme → Build Configuration → **Release**
3. Select iPhone 17 (or any available) simulator
4. Product → Run (⌘R)
