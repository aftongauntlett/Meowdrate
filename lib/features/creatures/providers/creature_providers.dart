import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../flood/providers/flood_providers.dart';
import '../creature_roster.dart';
import '../models/creature.dart';
import '../models/mood_band.dart';

/// Debug-only: forces a specific roster index instead of today's real pick.
class DebugCreatureIndexOverride extends Notifier<int?> {
  @override
  int? build() => null;

  void setOverride(int? value) => state = value;
}

final debugCreatureIndexOverrideProvider =
    NotifierProvider<DebugCreatureIndexOverride, int?>(DebugCreatureIndexOverride.new);

final creatureOfTheDayProvider = Provider<Creature>((ref) {
  final override = ref.watch(debugCreatureIndexOverrideProvider);
  return creatureOfTheDay(DateTime.now(), debugIndexOverride: override);
});

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
