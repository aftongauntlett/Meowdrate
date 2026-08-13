# Water Buddy — Product Redesign PRD

## Status

This document describes a redesign of the existing app's core loop and
supersedes the current points → shop → cosmetics system described in
[README.md](README.md). The hydration logging, streak, and reminder
infrastructure already in `lib/features/` stays; the pet/shop/points model
built on top of it is being replaced with what's described below.

## Vision

Most hydration/habit apps run on manufactured scarcity: you earn a trickle
of points and constantly feel like you can't afford the fun stuff, which
makes the app feel like it's optimizing for engagement, not for you. Water
Buddy inverts that. You start every day with abundance, and the entire loop
is about spending what you have on something good — not accumulating
enough to finally be allowed to enjoy the app.

The app is 100% free. No accounts, no ads, no in-app purchases, no login.
Everything lives on the device.

## Core Loop

The app opens on a scene that's flooded with water, swishing near the top
of the screen. Each logged drink recedes the flood a little. As the water
drops, a stranded creature is revealed and rescued — it flutters/swims off
with a small thank-you. Reach today's water goal and the flood fully
clears for the day.

- **Full water = a problem** (a flood), not a reward to protect. This
  keeps the "starts full, drains as you drink" mechanic legible: draining
  it is the good outcome, matching how drinking water actually works in
  your body.
- **Points** are earned per drink and spent same-day on picking one of a
  few small good deeds — "clean the beach," "feed a bird," "plant
  something." One light choice per day, not a shop, not a grind.
- **Missing the goal** has no *mechanical* punishment. The day's creature
  just stays shy/hidden and is there again tomorrow, and the streak
  resets quietly with no punishment screen. No lost items, no locked
  content, no broken-streak shaming — the whole point of this app is to
  not do what Finch does. The narrator is free to be sarcastic about it
  in the moment (see Voice & Tone) — that's writing, not a dark pattern,
  since nothing real is actually at stake.

## Persistence Model (Local-Only, Deliberately Shallow)

No backend, no accounts. Data lives in on-device storage
(`shared_preferences` already in use). Deliberately **not** keeping a
detailed history:

- **Today's progress** — persists through the day (needed for the loop to
  function), resets each day regardless.
- **A streak count** (consecutive days the goal was met) — kept. Losing a
  number stings far less than losing a curated collection, so this is
  worth the small amount of "something to lose" it reintroduces. Keep the
  messaging low-drama either way: no "you lost your streak!" moment on a
  miss, it just quietly starts counting from 0 again the next successful
  day.
- **No per-day archive / scrapbook / creature log.** A bird flutters off,
  says thanks, and that's the entire memory of the interaction — nothing
  is kept, so there's nothing specific to lose or grieve if storage resets.

This is the deliberate answer to "what if local storage loses my
progress": local storage isn't unreliable, it's just tied to one
device/install (uninstalling, wiping app storage, or switching phones
clears it). By not keeping anything worth mourning, that structural
limitation stops being a problem instead of needing a disclaimer to
manage anger about it.

**Copy for Settings/About screen** (value framing, not an apology, shown
once, not as a scary first-launch warning):

> No accounts, no cloud, nothing tracked. Everything lives on your phone —
> if you switch phones or reinstall, your streak starts over. That's the
> tradeoff for keeping this free and private.

## Keeping It Fresh Without a Backend

Since there's no login, every day mechanically starts from the same
state. Freshness has to come from content variety, not structural
progression:

- **Date-seeded rotation**: which creature shows up, which narrator line
  plays (see Voice & Tone below), pulled deterministically from a pool
  keyed off the date and trigger. Feels like content, needs no server.
- Pool sizes big enough that repeats aren't noticeable for months — sized
  per-trigger in Voice & Tone, since a line you hear 10x a day needs a
  bigger pool than one you hear once a week.

## Art & Audio — Self-Made First

The user isn't an artist or sound designer, but the goal is to keep the
app **100% made by them** before reaching for found/free assets online.
The core visual mechanic (a dynamically animating water level) is a
functional requirement anyway, which happens to be exactly what
procedural/code-drawn approaches are good at — no art skill required.

### Water background

Draw with Flutter's `CustomPainter`: two or three overlaid sine waves,
amplitude/offset animated over time, height driven by today's remaining
progress. No image assets. This is the same trick behind "cute duck game
made entirely of sine waves" — cheap, smooth, and it's already the visual
centerpiece of the whole app.

### Creatures

Build as simple flat vector shapes drawn in code (circles, ellipses,
bezier paths via `CustomPainter` or `CustomClipper`) rather than sourcing
sprite packs. A small roster (duck, otter, turtle, fish, frog...) built
from a shared set of primitive shapes keeps the style consistent across
the whole cast, and it's realistic for one person to draw entirely in
code — no vector art tool needed, though something like Figma/Inkscape
could help block out shapes first if drawing paths blind in code gets
hard.

### Sound

Self-made via a retro sound-effect generator rather than recording or
composing — tools like **jsfxr** (browser-based, free, generates short
procedural blips/chimes/chirps by tweaking a waveform with sliders, no
musical training needed) or **bfxr**. Export as short WAV/OGG clips:

- A soft chime on logging a drink
- A small "thank you" chirp when a creature is rescued
- A slightly bigger jingle when the day's goal is met

Keep sound minimal and easily muted — many users of habit apps play with
sound off entirely.

If self-made assets fall short later, free CC0 packs (Kenney.nl for
shapes/UI sounds, freesound.org for audio) are the fallback — but the
goal is to exhaust the self-made path first.

## Voice & Tone

The app's personality is a **sarcastic, self-aware narrator** in the
GLaDOS (Portal) / Stanley Parable tradition — dry, meta, a little
theatrical — rather than the "you're doing great, sweetie!" cheerfulness
of most habit apps. This is the primary retention hook in place of
everything this app deliberately doesn't have (accounts, streak-shaming,
locked content): curiosity about what the narrator says next.

**Two different kinds of "guilt," only one of which is in this app:**

- **Mechanical guilt** (rejected, unchanged from the rest of this doc) —
  actually losing something real: a pet gone forever, a locked feature, a
  broken streak treated as a failure state. None of that exists here. The
  creature that "drowns" is still fine tomorrow; the streak resets
  quietly with no punishment screen.
- **Voice guilt** (the whole point) — the narrator giving the player a
  hard time *about* the fiction, with zero mechanical teeth behind it.
  "Look what you did... are you proud of yourself?" lands as a joke
  specifically because nothing was actually lost. This is copywriting,
  not a dark pattern.

**Tone calibration:** mostly dry/wry (Stanley Parable register) for
everyday moments, with occasional sharper GLaDOS-level bite reserved for
bigger beats — a creature "drowning," a long absence — so those land
harder instead of every line competing at max intensity and burning out.

**Guardrail:** health/hydration jabs are fair game (the narrator can be
dramatic about organs, dehydration, etc.) as long as they stay
comedic/absurd hyperbole — a bit, not a real claim. Never tip into actual
medical alarm or anything that could read as genuine health anxiety
rather than a joke. The test: would this be funny read aloud in a
GLaDOS/Stanley Parable voice, or does it sound like a real warning? If
the latter, it's off-tone.

Sample lines, by trigger:

- **Drink logged:** "Oh good, you're drinking water. I'll alert the
  media."
- **Goal met:** *(bigger, more theatrical — this is the daily "win")*
- **Creature "drowns" / goal missed:** "Look what you did. Are you proud
  of yourself?"
- **Missed goal, health-jab variant:** something in the "enjoy those
  kidney stones" family — dehydration-adjacent, comedic-hyperbole
  register per the Guardrail above, not an actual medical warning.
- **Returning after a long absence:** "Oh. It's you. I'd almost finished
  grieving."

**Copy pool sizing**, by trigger frequency (higher-frequency triggers
need bigger pools to avoid the joke going stale):

- *Drink logged* (seen many times a day): largest pool, ~20–30 lines, mix
  of dry/sarcastic/occasionally-warm so it doesn't feel monotone.
- *Goal met* (once a day): ~10–15 lines, can lean into a bigger "victory
  bit" register.
- *Missed goal / creature drowned* (occasional): ~10–15 lines — this is
  where the sharper GLaDOS-tier lines live.
- *Long absence return* (rare): ~5–8 lines, since it's seen infrequently
  and can afford to be more specific/theatrical each time.

These are starting points, not hard requirements — size up whichever
category starts feeling repetitive first once it's actually in daily use.

## Time of Day & Theming

Two independent axes — one automatic and scene-only, one manual and
UI-wide.

### Live day/night scene (automatic)

The flood scene shifts live using the **device's local clock** — dawn,
day, dusk, night. Because a phone's local clock already reflects whatever
timezone it's set to, this naturally matches the user wherever they are
without collecting any location data. Real sunrise/sunset times vary by
season and latitude, and getting that precisely would require location
access, which conflicts with the no-data-collection principle — so use a
simple fixed clock-hour schedule instead:

| Band  | Hours (local) |
|-------|----------------|
| Dawn  | 5:00 – 7:00   |
| Day   | 7:00 – 18:00  |
| Dusk  | 18:00 – 20:00 |
| Night | 20:00 – 5:00  |

Starting point, not exact science — tune once the gradient is actually
visible and playable (e.g. if 6pm still reads as full daylight in most
seasons, nudge Dusk earlier).

- Sky gradient and the flood water's ambient color shift within these
  bands.
- Stars fade in during the night band, fade out at dawn.
- Recalculates periodically while the app is open (e.g. once a minute) so
  a user who leaves the app open across a band boundary can watch it
  shift live, not just on next launch.

### Dark/Light mode (manual, UI chrome)

A separate Light/Dark/System toggle in Settings, driving the app's UI
chrome (text, buttons, cards, nav) via Flutter's `ThemeData` — independent
of what the background scene is doing. The two compose freely: a user in
light UI mode can still be looking at a starry night scene, and vice
versa.

## Explicit Non-Goals

- No ads, no in-app purchases, no login/accounts, no backend.
- No detailed per-day history/scrapbook the user can lose and grieve.
- No punishing streak mechanics or permanent loss of pets/items for a
  missed day.
- No "shop" — points are spent same-day on flavor choices, not
  accumulated toward purchases.

## Decisions

- **Creature roster: ~10 creatures** (duck, otter, turtle, fish, frog,
  crab, seal, heron, dragonfly, beaver, or similar). Enough for a
  date-seeded pool to feel varied for months without repeating on
  consecutive days, small enough for one person to hand-draw as vector
  shapes in a reasonable amount of time. Easy to expand later since
  there's no migration cost — it's just a bigger pool to seed from.
- **Streak: kept**, low-drama on a miss (see Persistence Model above).
- **Time of day: tied to device local clock**, live-shifting scene with
  stars at night; separate manual Light/Dark/System toggle for UI chrome
  (see Time of Day & Theming above).

## Open Questions

- Exact clock-hour boundaries for dawn/day/dusk/night bands — tune once
  the gradient is actually visible and playable rather than guessing
  upfront.
- Note pool size for the encouragement copy ("You're doing great!" and
  friends) — same freshness-vs-effort tradeoff as the creature roster,
  worth sizing once a first batch of copy is drafted.
