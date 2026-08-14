import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../flood/providers/flood_providers.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../narrator_selector.dart';
import '../narrator_trigger.dart';

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
  if (level <= 0.0) {
    return selectNarratorLine(NarratorTrigger.goalMet);
  }

  final override = ref.watch(debugNarratorOccurrenceOverrideProvider);
  final drinkCount = ref.watch(hydrationSummaryProvider).value?.count ?? 0;
  final occurrence = override ?? drinkCount;

  if (occurrence == 0) {
    return ref.watch(openingLineOverrideProvider) ?? 'Keep drinking to clear the flood.';
  }
  return selectNarratorLine(NarratorTrigger.drinkLogged, occurrence: occurrence);
});
