# Manual testing guide

How to exercise every feature by hand. Use the in-app **debug panel**
(bug icon, top-right of Home — only visible in debug builds) to skip
waiting on real time/drinks for the checks below.

## 1. Fresh install / zero state

1. Debug panel → **Reset all local data**
2. Confirm: flood is full, today's cat is shown (idle sprite animation
   playing), caption reads "Keep drinking to clear the flood.",
   `0 / 2000 ml`, `0 drinks today`, Recent says "No drinks yet." No
   streak/day-count anywhere on this screen — that lives in Settings
   only (see §5).

## 2. Drink Moment flow

1. Tap **Log a drink**
2. Confirm the countdown starts at `00:15` and counts down once per
   second
3. Confirm **I drank** is disabled until the countdown hits `00:00`, and
   the hint text switches from "Hold on until the timer ends." to "Go
   ahead — I'm timing you."
4. Tap **Skip** on a fresh countdown instead — confirm it returns to
   Home with nothing logged (count/ml unchanged)
5. Redo and tap **I drank** once complete — confirm, back on Home:
   - Drinks-today count +1, total ml +250
   - The flood visibly drops (smoothly — see §3 for the animation check)
     and the narrator caption changes to a drink-logged line
   - New row appears at the top of Recent with the current time
   - No snackbar/toast appears — the caption change is the only
     confirmation now

## 3. Flood level + creature reveal

Flood level is derived live from today's total — use the debug panel
instead of logging drinks one at a time:

- **Drain flood (0%)** → water disappears, caption switches to a
  goal-met line, today's cat is fully visible
- **Flood full (100%)** → water covers almost the whole scene
- **Use real flood level** → returns to the real derived value
- **Next creature** → cycles the roster (Tabby / Box Cat / Dracula Cat)
  so you can check every sprite animates without waiting for date
  rollover
- **Animation smoothness**: watch the water for at least 10–15 seconds
  continuously — confirm it swishes smoothly with no visible "jump" or
  reset in the wave pattern. Same for stars at night (§6): confirm they
  render as small 4-point sparkles (not plain dots) and some visibly
  twinkle at different rates, not all in unison.

## 4. Daily goal + streak (Settings)

1. Debug panel → **Complete today's goal** (logs 2000ml in one shot)
2. Confirm: flood drains, a goal-met narrator line shows, and (if sound
   assets are present — see §8) the goal-met sound plays
3. Tap it again the same day — confirm the day-count does **not**
   double-count (only increments the first time the goal is met each
   day) — check via Settings, not Home (see step 5 below)
4. Debug panel → **+1 day streak** a few times, then open Settings (gear
   icon) → confirm the "Consistency" section's day count updates
   accordingly, phrased plainly ("N days in a row"), no fire icon, no
   celebratory styling

## 5. Narrator voice

- **Next narrator line** → cycles the drink-logged pool without needing
  to log real drinks; confirm the caption text changes each tap and
  doesn't repeat for a while
- **Preview goal-missed line** / **Preview long-absence line** (debug
  panel only) → shows a snackbar preview of a line from that pool;
  confirm it's sarcastic per PRD.md's Voice & Tone section, not an
  actual health warning. This debug preview is the only place a
  narrator line still shows in a snackbar — for real users it never
  does (see next bullet).
- To see a **real** goal-missed/long-absence event: reset, then edit
  `shared_preferences` directly to backdate `lastSeenDate`/
  `lastGoalMetDate`, or simply wait. On the next app open, confirm the
  line appears as the flood scene's own opening caption (not a popup),
  and that it's replaced by a normal drink-logged line the moment you
  log a drink

## 6. Time of day + theme

- Debug panel → **Dawn** / **Day** / **Dusk** / **Night** → confirm the
  flood scene's sky gradient and stars change immediately (most visible
  when the flood is also drained — see §3)
- **Use real time of day** → returns to the device clock
- Settings (gear icon) → switch between **System** / **Light** / **Dark**
  → confirm the app chrome (background, cards, buttons, text) changes,
  while the flood scene's sky/water/cat colors stay exactly the same
  regardless of which is selected — these are two independent systems
  by design (see PRD.md's Time of Day & Theming section)

## 7. Reminders

1. Tap the bell icon (top-right of Home)
2. First tap requests notification permission — accept the system prompt
3. Confirm the bell fills in (active state) and stays active after
   backgrounding/reopening the app
4. Tap again → confirm it cancels and the bell returns to outline state
5. This only produces real OS notifications on iOS/Android/macOS — on
   Chrome (web) it's expected to no-op or behave inconsistently, since
   browser notification permissioning is a different system

## 8. Persistence

1. Log a couple of drinks, build up a streak
2. Fully close the app (swipe away / quit, not just backgrounding)
3. Reopen — confirm the day-count (Settings) and theme preference are
   still there (state lives in `shared_preferences`, not memory), but
   today's drink log is day-scoped, not a long-term history — that's
   intentional, see PRD.md's Persistence Model

## Known placeholders (not bugs)

- No sound plays until self-made files are dropped into `assets/audio/`
  (see that folder's `README.md`) — this is silent by design, not a
  crash. No console error is expected either.
- `flutter run -d chrome` / `-d macos` can't fully exercise reminders —
  test those on a real iOS/Android device.
