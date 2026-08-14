# Meowdrate

A hydration app that starts full instead of empty. No points to grind,
no shop, no ads, no accounts — just a flood that recedes as you drink,
cats it rescues along the way, and a sarcastic narrator who has opinions
about your hydration habits.

See [PRD.md](PRD.md) for the full design rationale.

## What it is

The screen is a flood scene: water swishing near the top, sky shifting
with the real time of day. Each drink you log recedes the flood a
little, revealing the day's cat. Clear it fully and the cat says thanks;
leave it unfinished and the narrator will have a comment about that too
— but nothing is ever actually lost. No streak-shaming, no locked
content, no per-day history to grieve if you miss a day or lose the
phone. There's a day-count, but it's tucked away in Settings rather than
sitting on the home screen — the goal is better habits, not a number
pulling you back to check in (see PRD.md's Vision section).

Everything is stored locally — no backend, no login.

## Tech stack

- Flutter (Dart)
- Riverpod (`flutter_riverpod`) for state management
- `shared_preferences` for local persistence
- `audioplayers` for self-made sound effects (optional — the app runs
  silently until files are dropped in, see `assets/audio/README.md`)
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

See [TESTING.md](TESTING.md) for a manual test pass through every
feature, including a debug panel (debug builds only) for exercising
flood-level/creatures/narrator lines/time-of-day without waiting on real
time or real drinks.

## Folder structure

```
lib/
  main.dart                    App entrypoint, notification init
  app.dart                     MaterialApp + theme-mode wiring
  core/
    theme/                     Light/dark AppColors (ThemeExtension) + AppTheme
    storage/                   Thin shared_preferences + JSON wrapper
    time_of_day/                Dawn/day/dusk/night band logic + provider
    audio/                      Sound effect enum + playback service
    utils/                      Shared date helpers (iso date, date-seeded index)
  features/
    hydration/                 Drink logging: models, repository, providers, screens
    flood/                     Flood/streak state, the animated flood scene + painters
    creatures/                 Cat roster + sprite-sheet animation widget
    narrator/                  Sarcastic narrator copy pools + date-seeded selection
    settings/                   Light/Dark/System theme toggle, streak, credits
    reminders/                  Local notification scheduling
    debug/                       Debug-only panel for exercising every mechanic
assets/
  audio/                        Drop-in self-made sound effects (see its README)
  creatures/                    Cat sprite sheets (see its README for credits)
```

## Adding sound effects

`SoundService` looks for `assets/audio/drinkLogged.mp3` and
`goalMet.mp3` and silently skips playback if they're missing, so the app
runs fine before real sound is sourced. See `assets/audio/README.md` for
how to make these yourself (no recording equipment needed).

## Creature art credits

Cat sprites are from **Cat Pack** by toffeecraft
(https://toffeecraft.itch.io/cat-pack), free, credited in-app under
Settings → Credits. See `assets/creatures/README.md` for details.

## Design principles

- Clear boundaries: UI vs. state/providers vs. data/repositories
- Small, focused modules per feature (hydration / flood / creatures /
  narrator / settings / reminders / debug)
- Local-first persistence, no backend dependency — and deliberately
  shallow: no per-day history is kept, so there's nothing to lose
- Two independent theming axes: the flood scene's automatic day/night
  sky (device clock) and the user's manual Light/Dark/System chrome
  preference never affect each other
- Prefer self-made/procedural over found assets, but not dogmatically —
  see PRD.md's Creatures section for where that tradeoff went the other
  way
- Consistent styling via theme tokens
