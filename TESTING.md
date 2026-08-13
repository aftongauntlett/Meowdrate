# Manual testing guide

How to exercise every feature by hand. Use the in-app **debug panel**
(bug icon, top-right of Home — only visible in debug builds) to skip
waiting on real time/drinks for the streak/points/mood checks below.

## 1. Fresh install / zero state

1. Debug panel → **Reset all local data**
2. Confirm: pet shows the idle placeholder, "Feeling okay", `0 / 2000 ml`,
   `0 drinks today`, `0 day streak`, `0 points`, Recent says "No drinks yet."

## 2. Drink Moment flow

1. Tap **Log a drink**
2. Confirm the countdown starts at `00:15` and counts down once per second
3. Confirm **I drank** is disabled until the countdown hits `00:00`, and
   the hint text switches from "Hold on until the timer ends." to "Your
   pet is waiting…"
4. Tap **Skip** on a fresh countdown instead — confirm it returns to Home
   with nothing logged (count/ml unchanged)
5. Redo and tap **I drank** once complete — confirm:
   - Snackbar: "Nice — drink logged."
   - Drinks-today count +1, total ml +250
   - Progress bar advances
   - New row appears at the top of Recent with the current time
   - Pet mood switches to **happy** and label reads "Nice and hydrated!"
   - Points +10

## 3. Pet mood states

Mood is driven by time since the last logged drink — use the debug panel
instead of waiting:

- **Happy**: log a drink normally (§2) → mood should be happy immediately
- **Idle**: happens naturally ~20 min after a drink; not worth waiting for
  manually, just confirm it's the state whenever it's neither happy nor
  thirsty
- **Thirsty**: debug panel → **Simulate thirsty (4h ago)** → mood switches
  to thirsty ("Getting thirsty…") without a real wait. Note this also adds
  250ml to today's total (it's a real drink entry, just backdated).

## 4. Daily goal + streaks

1. Debug panel → **Complete today's goal** (logs 2000ml in one shot)
2. Confirm: progress bar fills to 100%, streak becomes `1 day streak`,
   points jump by `10 + 25` (log + daily-goal bonus)
3. Tap it again the same day — confirm streak does **not** double-count
   (goal-met bonus only fires once per calendar day)
4. Debug panel → **+1 day streak** a few times — confirm the streak chip
   updates immediately each tap (this simulates *previous* days, so it
   won't fight with today's real goal-completion logic)

## 5. Points + Shop ("Closet")

1. Debug panel → **+100 points** (repeat until you have enough for
   whatever you want to test)
2. Tap the points chip on Home → opens **Closet**
3. Pick an item below your balance → **Unlock** should be tappable;
   confirm points deduct by the item's cost and the button changes to
   **Equip**
4. Tap **Equip** → go back to Home → confirm the accessory emoji renders
   over the pet
5. Return to Closet → **Unequip** → confirm the accessory disappears from
   Home
6. Try an item costing more than your balance → **Unlock** should be
   disabled (greyed out)
7. Debug panel → **-100 points** to test the insufficient-funds state
   without unlocking everything first

## 6. Reminders

1. Tap the bell icon (top-right of Home)
2. First tap requests notification permission — accept the system prompt
3. Confirm the bell fills in (active state) and stays active after
   backgrounding/reopening the app
4. Tap again → confirm it cancels and the bell returns to outline state
5. This only produces real OS notifications on iOS/Android/macOS — on
   Chrome (web) it's expected to no-op or behave inconsistently, since
   browser notification permissioning is a different system

## 7. Persistence

1. Log a couple of drinks, unlock/equip an item, build up a streak
2. Fully close the app (swipe away / quit, not just backgrounding)
3. Reopen — confirm everything from step 1 is still there (state lives in
   `shared_preferences`, not memory)

## Known placeholders (not bugs)

- Pet animations are an emoji placeholder until real Lottie files are
  dropped into `assets/pet/` (see `assets/pet/README.md`) — the
  `Failed to load resource ... idle.json 404` console message is expected
  until then.
- `flutter run -d chrome` / `-d macos` can't fully exercise reminders —
  test those on a real iOS/Android device.
