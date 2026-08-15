import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../flood/providers/flood_providers.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../../settings/providers/daily_goal_providers.dart';
import '../narrator_selector.dart';
import '../narrator_trigger.dart';

/// Shown exactly once per day: the first drink logged *after* the goal is
/// already met. Kept out of goalMetLines on purpose — that pool is
/// date-seeded and would happily resurface this on some later day for an
/// ordinary goal-met moment, which isn't what this line is for.
const _firstOverGoalLine = 'Wow, going above and beyond. Color me impressed.';

/// Debug-only: forces the drink-logged pool to a specific occurrence
/// instead of tracking today's real drink count, so the pool can be
/// stepped through without logging real drinks.
class DebugNarratorOccurrenceOverride extends Notifier<int?> {
  @override
  int? build() => null;

  void setOverride(int? value) => state = value;
}

final debugNarratorOccurrenceOverrideProvider =
    NotifierProvider<DebugNarratorOccurrenceOverride, int?>(
  DebugNarratorOccurrenceOverride.new,
);

/// A goal-missed/long-absence line noticed on this app open (see
/// FloodNotifier.consumePendingRolloverEvent), shown as the flood scene's
/// opening caption instead of a separate popup. Set once by
/// FloodHomeScreen at startup; null on days with nothing to report.
class OpeningLineOverride extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final openingLineOverrideProvider =
    NotifierProvider<OpeningLineOverride, String?>(OpeningLineOverride.new);

/// The line shown in the flood scene right now: a goal-met line once
/// today's flood is fully cleared, otherwise a drink-logged line keyed to
/// how many drinks have been logged today — or, before the first one,
/// either a leftover goal-missed/long-absence line from opening the app
/// (see openingLineOverrideProvider) or a neutral prompt.
final currentNarratorLineProvider = Provider<String>((ref) {
  final level = ref.watch(floodLevelProvider);
  final override = ref.watch(debugNarratorOccurrenceOverrideProvider);
  final drinkCount = ref.watch(hydrationSummaryProvider).value?.count ?? 0;
  final occurrence = override ?? drinkCount;

  if (level <= 0.0) {
    // Goal already met — but drinking past it shouldn't just freeze on
    // the exact-goal line forever. The first drink logged after goal is
    // its own one-time reaction; anything past that falls back to
    // cycling the regular goal-met pool (still varied by how many extra
    // drinks it's been, rather than pinned to a single line).
    final goalGlasses = ref.watch(dailyGoalGlassesProvider).value ?? kDefaultDailyGoalGlasses;
    final overGoal = occurrence - goalGlasses;
    if (overGoal == 1) {
      return _firstOverGoalLine;
    }
    if (overGoal > 1) {
      return selectNarratorLine(NarratorTrigger.goalMet, occurrence: overGoal);
    }
    return selectNarratorLine(NarratorTrigger.goalMet);
  }

  if (occurrence == 0) {
    return ref.watch(openingLineOverrideProvider) ?? 'Keep drinking to help the cat!';
  }
  return selectNarratorLine(NarratorTrigger.drinkLogged, occurrence: occurrence);
});
