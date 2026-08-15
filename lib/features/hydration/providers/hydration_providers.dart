import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_effect.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/storage/local_store.dart';
import '../../flood/providers/flood_providers.dart';
import '../../reminders/reminder_coordinator.dart';
import '../data/hydration_repository.dart';
import '../hydration_constants.dart';
import '../models/hydration_entry.dart';

final localStoreProvider = Provider<LocalStore>((ref) => const LocalStore());

final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  return HydrationRepository(ref.watch(localStoreProvider));
});

class HydrationSummaryNotifier extends AsyncNotifier<DrinksTodaySummary> {
  @override
  Future<DrinksTodaySummary> build() {
    return ref.watch(hydrationRepositoryProvider).getDrinksTodaySummary();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(hydrationRepositoryProvider).getDrinksTodaySummary(),
    );
  }
}

final hydrationSummaryProvider =
    AsyncNotifierProvider<HydrationSummaryNotifier, DrinksTodaySummary>(
  HydrationSummaryNotifier.new,
);

/// Timestamp of the most recent drink ever logged (any day) — independent
/// of "today"'s totals.
final lastDrinkAtProvider = FutureProvider<DateTime?>((ref) async {
  final drinks = await ref.watch(hydrationRepositoryProvider).getAllDrinks();
  if (drinks.isEmpty) {
    return null;
  }

  final latestMs = drinks.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b);
  return DateTime.fromMillisecondsSinceEpoch(latestMs);
});

/// Orchestrates logging a drink across the hydration + flood features so
/// screens don't need to know how the streak is derived.
class HydrationController {
  HydrationController(this._ref);

  final Ref _ref;

  Future<void> logDrink({int amountMl = kDrinkAmountMl}) async {
    await _ref.read(hydrationRepositoryProvider).logDrink(amountMl);
    await _ref.read(hydrationSummaryProvider.notifier).refresh();
    _ref.invalidate(lastDrinkAtProvider);

    final summary = _ref.read(hydrationSummaryProvider).value ?? DrinksTodaySummary.empty;
    await _ref.read(floodStateProvider.notifier).registerDrinkLogged(
          totalMlToday: summary.totalAmountMl,
        );
    unawaited(_ref.read(soundServiceProvider).play(SoundEffect.drinkLogged));

    // Logging a drink is the one moment reminders actually need to react
    // to immediately — push the next nudge out, or silence it entirely if
    // this was the one that hit today's goal.
    try {
      await _ref.read(reminderCoordinatorProvider).reconcile();
    } catch (_) {
      // Notifications aren't available on this platform/environment.
    }
  }

  /// Debug-only: backdates a drink entry (e.g. "4 hours ago") to exercise
  /// time-based mechanics without waiting on real time. Deliberately skips
  /// the streak — it's simulating the clock, not a real action.
  Future<void> debugLogBackdated(Duration ago, {int amountMl = kDrinkAmountMl}) async {
    await _ref
        .read(hydrationRepositoryProvider)
        .logDrink(amountMl, at: DateTime.now().subtract(ago));
    await _ref.read(hydrationSummaryProvider.notifier).refresh();
    _ref.invalidate(lastDrinkAtProvider);
  }

  /// Clears today's logged drinks only — yesterday and earlier (and the
  /// streak they've built) are untouched. The flood level corrects itself
  /// on the next read since it's derived live from today's total rather
  /// than stored.
  Future<void> resetToday() async {
    await _ref.read(hydrationRepositoryProvider).clearToday();
    await _ref.read(hydrationSummaryProvider.notifier).refresh();
    _ref.invalidate(lastDrinkAtProvider);
  }

  /// Debug-only: wipes all local hydration + flood data, for testing the
  /// fresh-install / zero-state experience.
  Future<void> debugResetAll() async {
    await _ref.read(hydrationRepositoryProvider).clearAll();
    await _ref.read(floodStateProvider.notifier).debugReset();
    await _ref.read(hydrationSummaryProvider.notifier).refresh();
    _ref.invalidate(lastDrinkAtProvider);
  }
}

final hydrationControllerProvider = Provider((ref) => HydrationController(ref));
