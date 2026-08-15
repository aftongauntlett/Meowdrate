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
