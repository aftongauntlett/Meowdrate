import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../pet/providers/pet_providers.dart';
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

/// Timestamp of the most recent drink ever logged (any day), used to drive
/// the pet's mood — independent of "today"'s totals.
final lastDrinkAtProvider = FutureProvider<DateTime?>((ref) async {
  final drinks = await ref.watch(hydrationRepositoryProvider).getAllDrinks();
  if (drinks.isEmpty) {
    return null;
  }

  final latestMs = drinks.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b);
  return DateTime.fromMillisecondsSinceEpoch(latestMs);
});

/// Orchestrates logging a drink across the hydration + pet features so
/// screens don't need to know how points/streaks are derived.
class HydrationController {
  HydrationController(this._ref);

  final Ref _ref;

  Future<void> logDrink({int amountMl = kDrinkAmountMl}) async {
    await _ref.read(hydrationRepositoryProvider).logDrink(amountMl);
    await _ref.read(hydrationSummaryProvider.notifier).refresh();
    _ref.invalidate(lastDrinkAtProvider);

    final summary = _ref.read(hydrationSummaryProvider).value ?? DrinksTodaySummary.empty;
    await _ref.read(petStateProvider.notifier).registerDrinkLogged(
          totalMlToday: summary.totalAmountMl,
        );
  }
}

final hydrationControllerProvider = Provider((ref) => HydrationController(ref));
