# UI sprites

Three sources, all at native resolution with nearest-neighbor scaling
(same as the creature sprites):

- `CatUIFree/free.png` — a small cat-themed pixel UI kit (toffeecraft).
- `CatUIPaid/catUI.png` — the paid version of the same kit (toffeecraft).
- `UI Bundle.zip` → `PastelUi.png` — a separate, larger "game UI kit"
  pack (buttons, bordered panels, icon-buttons in many palette themes;
  we use the blue-toned pieces). **Credit unknown** — this pack didn't
  come with a license/author file; add one to this README and to
  Settings → Credits once known, same as every other third-party asset
  here.

| File | Source | Used for |
|------|--------|----------|
| `btn_pill_blue.png` | PastelUi | `PixelButton`'s background — used as-is, no tinting (an earlier version tinted a pale CatUIPaid pill toward the theme color via `BlendMode.modulate`, which is what made it look washed out) |
| `panel_card.png` | PastelUi | Background for the Settings sheet itself *and* each section within it (nine-sliced to two different sizes) — the "tab at the top" card shape |
| `icon_button_plus.png` / `icon_button_minus.png` | PastelUi | Daily goal stepper — a real small button asset (background baked in), not a bare glyph over hand-drawn chrome. Pulled from PastelUi's periwinkle-blue icon-button variant specifically (`#8CAAEE`), matching `btn_pill_blue.png` exactly — an earlier version used the gray-blue variant, which didn't read as the same UI kit as the rest of the app's blue buttons |
| `icon_plus.png` | CatUIPaid, bare plus glyph | `PixelIcon` on "Log a drink" |
| `icon_check.png` | CatUIPaid, bare check glyph | `PixelIcon` on "I drank" (Drink Moment) |
| `icon_x.png` | CatUIPaid, bare X glyph | "Skip" (Drink Moment) |
| `confirm_dialog_cat.png` | CatUIPaid, sleeping-cat YES/NO dialog | "Reset all local data" confirmation (debug panel) |
| `sleeping_cat.png` | CatUIFree, sleeping cat illustration | "No drinks yet" empty state (Recent); also peeks over the Settings Credits card |

The `icon_*.png` glyphs are bare (no button chrome baked in) and mostly
black outline art, so they're recolored via `PixelIcon`
(`BlendMode.srcIn`) rather than used at their native color — that's what
keeps them legible against dark surfaces instead of vanishing. The
`btn_pill_blue.png` / `panel_card.png` / `icon_button_*.png` pieces are
used at their native color instead, deliberately — they're fixed game
art rather than theme-adaptive UI, same as Focus Friend/Finch don't
repaint their buttons for system dark mode.
