# Schwiizerdüütsch – Learn Swiss German 🇨🇭

An iOS app (SwiftUI, iOS 17+) that teaches Swiss German (Zürich dialect) through short lessons, audio, sentence building, a dialect explorer and a shareable "How Swiss are you?" quiz.

- **Bundle ID:** `com.connexa.schweizerdeutsch`
- **Monetisation:** free chapters 1–2, Premium via StoreKit 2 (yearly with 7-day trial, monthly, lifetime)
- **Privacy:** no accounts, no analytics, no ads – everything is stored on device.

## Build
```bash
brew install xcodegen
xcodegen generate
open Schwiizerduetsch.xcodeproj   # scheme has a local StoreKit config (Products.storekit)
```

## Structure
- `Schwiizerduetsch/Models` – curriculum (15 units, 180+ phrases), dialect data, quiz
- `Schwiizerduetsch/Services` – progress store, StoreKit 2, speech, notifications
- `Schwiizerduetsch/Views` – home path, lessons/exercises, paywall, practice, dialects, profile
- `docs/` – GitHub Pages (privacy policy, support)
- `Store/` – App Store metadata (ASO) and screenshot tooling
- `scripts/` – icon generator, simulator helpers

Debug-only launch arguments for screenshots: `-demo -premium -tab N -paywall -mockprices -lesson <id> -en`.
