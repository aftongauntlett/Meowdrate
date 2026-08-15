# Sound effects

Drop-in short sound effects for the flood scene. The app runs fine
without these — a missing file is skipped silently (see
`lib/core/audio/sound_service.dart`) — so there's no rush to source them
before the rest of the app is working.

Per `PRD.md`'s "Art & Audio — Self-Made First" section, the goal is to
make these yourself with a procedural sound-effect generator rather than
recording or composing — **jsfxr** (https://sfxr.me, browser-based, free,
no install) or **bfxr** both work well for short retro chime/chirp/jingle
sounds. Export as WAV or MP3 and drop the file in here with the exact
name below — no code changes needed.

| File | Plays when | Feel |
|------|-----------|------|
| `drinkLogged.mp3` | Every drink logged | Soft, short chime |
| `goalMet.mp3` | The day's flood fully clears | A bit bigger — this is the daily "win" |
| `creatureRescued.mp3` | Not wired yet — reserved for a future distinct reveal moment, since draining the flood *is* meeting the goal in the current mechanic | Small chirp/thank-you |
| `drinkMomentSong.mp3` | Background music during the 15s Drink Moment countdown (`drink_moment_screen.dart`) | Longer than the other three — this one isn't a short SFX, it can be an actual short loop/track |
| `narratorBlip.mp3` | Every few characters while the narrator's line types itself out (`typewriter_text.dart`) | A single short, soft blip — it repeats dozens of times per line, so it needs to disappear into the background rather than announce itself. Current file is a synthesized placeholder tone; swap for a jsfxr blip when there's time |
| `uiTap.mp3` | The settings gear (open) and most controls inside the settings sheet (`settings_screen.dart`, `flood_home_screen.dart`) | A quick, soft click — one shared tap sound for all of these rather than a distinct one per control. Current file is a synthesized placeholder tone; swap for a jsfxr click when there's time |
| `uiTapNegative.mp3` | The settings sheet's close (X) button, the "-" side of the daily-goal stepper, and "No" on the reset-today confirm dialog (`settings_screen.dart`, `confirm_dialog.dart`) | Same as `uiTap.mp3` but pitched a bit lower — a "closing/declining" counterpart to its neutral/affirmative sibling. Current file is a synthesized placeholder tone; swap for a jsfxr click when there's time |

Keep the short-effect files well under a second and quiet by default —
many users play habit apps with sound off entirely, so these should be a
nice-to-have detail, not something the app depends on to feel complete.

Unlike the three effects above, `drinkMomentSong.mp3` isn't self-made —
it's a found track, so its license needs a visible credit. That credit
lives in Settings (`lib/features/settings/screens/settings_screen.dart`)
rather than here alone; update it if you swap the file. It also plays on
its own `AudioPlayer` in `drink_moment_screen.dart` rather than through
`sound_service.dart`, so a one-shot SFX (e.g. `drinkLogged` when the user
taps through) doesn't cut it off mid-song.
