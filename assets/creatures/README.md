# Creature sprites

Cat sprites from **Cat Mega Pack** by toffeecraft
(https://toffeecraft.itch.io/cat-pack), free, used with credit per the
pack's terms (also shown in-app under Settings → Credits).

Pochi is the only cat in the app — the one with genuinely distinct
per-mood art (hissing / grooming / sleeping), rather than a single idle
loop reused across moods.

| File | Frames | Mood band it's used for |
|------|--------|-----|
| `pochi_sad.png` | 2 × 64×64 | Neutral — flood half drained |
| `pochi_neutral.png` | 4 × 64×64 | Sad — flood mostly full |
| `pochi_happy.png` | 4 × 64×64 | Happy — flood mostly cleared |

The file names follow the original hissing/grooming/sleeping crop names
from `CatMegaFree/PochiFree/FreeSprites.png`, but which pose reads as
more "sad" vs. "on edge" didn't match those names once actually seeing
them in the flood scene — see the swap noted in creature_roster.dart. The
mood-band column above reflects what's actually wired up today, not the
file name.

All sheets are sliced and animated at runtime, rendered with
nearest-neighbor scaling (`FilterQuality.none`) so the pixel art stays
crisp instead of blurring when scaled up.

## `pochi_drink_*.png`

Six one-off poses used only on the drink-moment countdown screen (via
`SpriteAnimation.clipOverride`, see creature_roster.dart's
`pochiDrinkPoses`) — not part of Pochi's regular sad/neutral/happy mood
set. One is picked at random each time the screen opens
(`drink_moment_screen.dart`'s `_pose`); `MoodBand.happy` still drives the
shared tint/speed/bounce regardless of which pose is chosen. Frames come
from a different, separately-licensed pack (`RetroCatsPaid.zip` in the
repo root, `Cats/Sprites/`) rather than the toffeecraft sheet the mood
clips above use.

| File | Source frame | Frames |
|------|------|--------|
| `pochi_drink_idle.png` | `Idle.png` | 6 × 64×64 |
| `pochi_drink_excited.png` | `Excited.png` | 3 × 64×64 |
| `pochi_drink_happy.png` | `Happy.png` | 10 × 64×64 |
| `pochi_drink_run.png` | `Running.png` | 6 × 64×64 |
| `pochi_drink_box2.png` | `Box2.png` | 10 × 64×64 |
| `pochi_drink_relaxing.png` | `Chilling.png` | 8 × 64×64 |

**TODO:** add a Settings → Credits line for this pack once its
source/license terms are confirmed — `RetroCatsPaid.zip` didn't include a
license or readme file to source that from.
