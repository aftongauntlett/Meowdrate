import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../creature_roster.dart';
import '../models/creature.dart';
import '../models/mood_band.dart';
import '../../flood/providers/flood_providers.dart';

/// The only cat in the app right now — see creature_roster.dart.
final creatureOfTheDayProvider = Provider<Creature>((ref) => pochi);

/// Sad while the flood's mostly still there, happy once it's mostly
/// cleared — same cat all day, just reacting to today's progress.
final moodBandProvider = Provider<MoodBand>((ref) {
  final level = ref.watch(floodLevelProvider);
  if (level > 0.66) {
    return MoodBand.sad;
  }
  if (level > 0.33) {
    return MoodBand.neutral;
  }
  return MoodBand.happy;
});
