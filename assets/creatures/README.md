# Creature sprites

Cat sprites from **Cat Pack** and **Cat Mega Pack** by toffeecraft
(https://toffeecraft.itch.io/cat-pack), free, used with credit per the
pack's terms (also shown in-app under Settings → Credits). Only the cat
animations are used — the furniture/UI tilesets from the same packs
aren't part of this app.

| File | Frames | Cat | Mood |
|------|--------|-----|------|
| `idle.png` | 10 × 32×32 | Tabby | (single animation, all moods) |
| `box.png` | 4 × 32×32 | Box Cat | (single animation, all moods) |
| `dracula.png` | 6 × 32×32 | Dracula Cat | (single animation, all moods) |
| `pochi_sad.png` | 2 × 64×64 | Pochi | Sad — flood mostly full |
| `pochi_neutral.png` | 4 × 64×64 | Pochi | Neutral — flood partway drained |
| `pochi_happy.png` | 4 × 64×64 | Pochi | Happy — flood mostly cleared |

The `pochi_*` files are hand-cropped from `CatMegaFree/PochiFree/FreeSprites.png`
(hissing / grooming / sleeping animations respectively), repacked into
uniform-cell horizontal strips to match the slicing convention the other
sprites already use.

Tabby, Box Cat, and Dracula Cat only have one real animation each, so
they use it for all three moods — the mood still comes through via
tint/speed modulation at runtime (see
`lib/features/creatures/widgets/sprite_animation.dart`) rather than a
frame swap. Pochi is the only cat with genuinely distinct per-mood art.

All sheets are sliced and animated at runtime, rendered with
nearest-neighbor scaling (`FilterQuality.none`) so the pixel art stays
crisp instead of blurring when scaled up.
