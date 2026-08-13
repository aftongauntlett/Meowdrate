# Water Buddy

A small hydration companion app: log water, watch a pet react, build a
streak, and unlock cosmetics for your buddy.

## What it is

A focused, playful hydration tracker with a pet companion whose mood
reflects how recently you've had water, a daily goal + streak loop, and a
points-based shop for cosmetic accessories. Everything is stored locally —
no backend.

## Tech stack

- Flutter (Dart)
- Riverpod (`flutter_riverpod`) for state management
- `shared_preferences` for local persistence
- `lottie` for pet mood animations (with a graceful placeholder fallback)
- `flutter_local_notifications` for hydration reminders

## How to run

### Prerequisites

- Flutter SDK (`brew install --cask flutter`)
- Chrome (web), or Xcode/Android Studio for simulators/devices

### Install

```bash
flutter pub get
```

### Run

```bash
flutter run -d chrome   # easiest — no simulator/emulator required
flutter run              # picks any connected device/simulator
```

Useful commands:

```bash
flutter analyze
flutter test
```

## Folder structure

```
lib/
  main.dart                    App entrypoint, notification init
  app.dart                     MaterialApp + theme wiring
  core/
    theme/                     Design tokens (colors, spacing, radius) + ThemeData
    storage/                   Thin shared_preferences + JSON wrapper
  features/
    hydration/                 Drink logging: models, repository, providers, screens
    pet/                       Pet mood, points/streak state, PetView animation widget
    shop/                      Cosmetic unlock catalog + screen
    reminders/                 Local notification scheduling
assets/
  pet/                         Drop-in Lottie animations (see assets/pet/README.md)
```

## Adding pet animations

`PetView` looks for `assets/pet/idle.json`, `happy.json`, and
`thirsty.json` (Lottie files) and falls back to an emoji placeholder if
they're missing, so the app runs fine before real art is sourced. See
`assets/pet/README.md` for details.

## Design principles

- Clear boundaries: UI vs. state/providers vs. data/repositories
- Small, focused modules per feature (hydration / pet / shop / reminders)
- Local-first persistence, no backend dependency
- Consistent styling via theme tokens
