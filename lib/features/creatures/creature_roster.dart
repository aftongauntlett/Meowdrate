import 'models/creature.dart';

/// We only rescue one cat — see assets/creatures/README.md for sprite
/// credits (Cat Pack / Cat Mega Pack by toffeecraft, itch.io).
///
/// Pochi is drawn from `pochi_sad.png`/`pochi_neutral.png`/`pochi_happy.png`.
/// The sad/neutral pair is intentionally swapped relative to the file
/// names: the `pochi_sad.png` pose reads as more startled/on-edge, so it's
/// used for MoodBand.neutral (flood half drained), while `pochi_neutral.png`
/// reads as the more distressed pose, so it's used for MoodBand.sad (flood
/// still mostly full).
const pochi = Creature(
  id: 'pochi',
  name: 'Pochi',
  sad: SpriteClip(spriteAsset: 'creatures/pochi_neutral.png', frameCount: 4),
  neutral: SpriteClip(spriteAsset: 'creatures/pochi_sad.png', frameCount: 2),
  happy: SpriteClip(spriteAsset: 'creatures/pochi_happy.png', frameCount: 4),
  frameSize: 64,
  frameDuration: Duration(milliseconds: 220),
);
