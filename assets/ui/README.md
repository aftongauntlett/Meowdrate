# UI sprites

Four sources, all at native resolution with nearest-neighbor scaling
(same as the creature sprites):

- `CatUIFree/free.png` — a small cat-themed pixel UI kit (toffeecraft).
- `CatUIPaid/catUI.png` — the paid version of the same kit (toffeecraft).
- `UI Bundle.zip` → `PastelUi.png` — a separate, larger "game UI kit"
  pack (buttons, bordered panels, icon-buttons in many palette themes;
  we use the blue-toned pieces). **Credit unknown** — this pack didn't
  come with a license/author file; add one to this README and to
  Settings → Credits once known, same as every other third-party asset
  here.
- `RetroCatsPaid.zip` (repo root) → `Cats/AllCats*.png` — a separate,
  more detailed/shaded cat sprite pack, six palette variants of the same
  sheet of poses. **Credit unknown**, same caveat as PastelUi above.
  The same pack's `CatItems/Decorations/CatRoomDecorations.png` sheet
  also has a grid of pet bowls (food and water, four color variants
  each) — that's where `water_bowl.png` is cropped from.

| File | Source | Used for |
|------|--------|----------|
| `btn_pill_blue.png` | PastelUi | `PixelButton`'s background — used as-is, no tinting (an earlier version tinted a pale CatUIPaid pill toward the theme color via `BlendMode.modulate`, which is what made it look washed out) |
| `panel_card.png` | PastelUi | Background for the Settings sheet itself *and* each section within it (nine-sliced to two different sizes) — the "tab at the top" card shape |
| `icon_button_plus.png` / `icon_button_minus.png` | PastelUi | Daily goal stepper — a real small button asset (background baked in), not a bare glyph over hand-drawn chrome. Pulled from PastelUi's periwinkle-blue icon-button variant specifically (`#8CAAEE`), matching `btn_pill_blue.png` exactly — an earlier version used the gray-blue variant, which didn't read as the same UI kit as the rest of the app's blue buttons |
| `icon_plus.png` | CatUIPaid, bare plus glyph | `PixelIcon` on "Log a drink" |
| `icon_check.png` | CatUIPaid, bare check glyph | `PixelIcon` on "I drank" (Drink Moment) |
| `icon_x.png` | CatUIPaid, bare X glyph | "Skip" (Drink Moment) |
| `confirm_dialog_cat.png` | CatUIPaid, sleeping-cat YES/NO dialog | "Reset all local data" confirmation (debug panel) |
| `sleeping_cat.png` | CatUIFree, sleeping cat illustration | "No drinks yet" empty state (Recent) |
| `water_bowl.png` | RetroCatsPaid, light-blue water bowl, cropped from `CatRoomDecorations.png` | Trailing icon on each Recent timeline row, next to "Meowdrated" + the clock time |
| `cat_sitting_grey.png` / `cat_stretch_white.png` / `cat_curled_cream.png` / `cat_peekbox_orange.png` / `cat_sit_tuxedo.png` / `cat_whiskers_black.png` / `cat_prayer_cream.png` / `cat_boxnap_grey.png` | RetroCatsPaid, one pose each, cropped from `AllCats*.png` | Peek over the 8 Settings panels (Appearance / Glasses / Reminders / Sound / Consistency / Credits / Support / About your data, respectively) — a distinct pose and color per card instead of repeating one silhouette in different colors, replacing the earlier `curled_cat_*`/`awake_cat_*`/`paw_print.png` (CatUIPaid) set. The old set is gone from disk; `CatUIPaid.zip` in the repo root still has the source crop coordinates if it's ever wanted again. |

`sleeping_cat.png` is cropped tight to its content (43×32) — it used to
carry a few pixels of transparent padding baked into the canvas (58×42),
left over from wherever it was originally exported. That's invisible
where it's used standalone (the Recent empty state), but is the
convention every other tight-cropped peek asset here follows too
(`Image.asset(width:)` scales the whole canvas, padding included, so
stray padding throws off the apparent size at a shared `width`).

The Drink Moment screen's "watching" line was tried as a cat-peeking
nameplate banner (`nameplate_cat.png`, since removed) in a few different
forms — stretched via `Image.centerSlice` (corrupted the cat on Flutter
web's nine-patch renderer), then a code-drawn pill-plus-cat composite,
then the real sprite scaled uniformly. None of it read better than the
plain text it replaced, so it's back to a plain `Text` and the asset is
gone.

The `icon_*.png` glyphs are bare (no button chrome baked in) and mostly
black outline art, so they're recolored via `PixelIcon`
(`BlendMode.srcIn`) rather than used at their native color — that's what
keeps them legible against dark surfaces instead of vanishing. The
`btn_pill_blue.png` / `panel_card.png` / `icon_button_*.png` pieces are
used at their native color instead, deliberately — they're fixed game
art rather than theme-adaptive UI, same as Focus Friend/Finch don't
repaint their buttons for system dark mode.
