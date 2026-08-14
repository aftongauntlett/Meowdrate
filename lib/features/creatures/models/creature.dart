import 'mood_band.dart';

/// A single horizontal sprite strip: [frameCount] uniform frames, each
/// [Creature.frameSize] square, in [spriteAsset] (path under
/// assets/creatures/).
class SpriteClip {
  const SpriteClip({required this.spriteAsset, required this.frameCount});

  final String spriteAsset;
  final int frameCount;
}

class Creature {
  const Creature({
    required this.id,
    required this.name,
    required this.sad,
    required this.neutral,
    required this.happy,
    this.frameSize = 32,
    this.frameDuration = const Duration(milliseconds: 150),
  });

  final String id;
  final String name;

  /// Mood-specific clips. Most creatures only have one real animation, so
  /// all three point at the same SpriteClip — mood still reads through
  /// tint/speed modulation (see SpriteAnimation). Creatures with real
  /// distinct per-mood art (e.g. Pochi) use genuinely different clips.
  final SpriteClip sad;
  final SpriteClip neutral;
  final SpriteClip happy;

  /// Width/height of a single frame, in source pixels — shared across
  /// this creature's mood clips so switching moods doesn't jump size.
  final int frameSize;

  final Duration frameDuration;

  SpriteClip clipFor(MoodBand mood) {
    switch (mood) {
      case MoodBand.sad:
        return sad;
      case MoodBand.neutral:
        return neutral;
      case MoodBand.happy:
        return happy;
    }
  }
}
