import '../../core/utils/date_seed.dart';
import 'models/creature.dart';

/// We only rescue cats — see assets/creatures/README.md for sprite
/// credits (Cat Pack / Cat Mega Pack by toffeecraft, itch.io).
const _tabbyIdle = SpriteClip(spriteAsset: 'creatures/idle.png', frameCount: 10);
const _boxIdle = SpriteClip(spriteAsset: 'creatures/box.png', frameCount: 4);
const _draculaIdle = SpriteClip(spriteAsset: 'creatures/dracula.png', frameCount: 6);

const creatureRoster = <Creature>[
  // These three only have one real animation each, so all three moods
  // point at the same clip — mood still comes through via the tint/speed
  // modulation in SpriteAnimation.
  Creature(id: 'tabby', name: 'Tabby', sad: _tabbyIdle, neutral: _tabbyIdle, happy: _tabbyIdle),
  Creature(id: 'box_cat', name: 'Box Cat', sad: _boxIdle, neutral: _boxIdle, happy: _boxIdle),
  Creature(
    id: 'dracula_cat',
    name: 'Dracula Cat',
    sad: _draculaIdle,
    neutral: _draculaIdle,
    happy: _draculaIdle,
  ),
  // Pochi has real distinct per-mood animations: hissing (flood's still
  // high), grooming/settling (partway there), sleeping peacefully (safe).
  Creature(
    id: 'pochi',
    name: 'Pochi',
    sad: SpriteClip(spriteAsset: 'creatures/pochi_sad.png', frameCount: 2),
    neutral: SpriteClip(spriteAsset: 'creatures/pochi_neutral.png', frameCount: 4),
    happy: SpriteClip(spriteAsset: 'creatures/pochi_happy.png', frameCount: 4),
    frameSize: 64,
    frameDuration: Duration(milliseconds: 220),
  ),
];

/// Which cat shows up today — same date-seeded selection the narrator's
/// line pools use (see core/utils/date_seed.dart), just with its own
/// salt so the two don't pick in lockstep.
Creature creatureOfTheDay(DateTime date, {int? debugIndexOverride}) {
  final index = debugIndexOverride ??
      dateSeededIndex(date, creatureRoster.length, salt: 9001);
  return creatureRoster[index % creatureRoster.length];
}
