import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hydration/hydration_constants.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../../shop/models/shop_item.dart';
import '../data/pet_repository.dart';
import '../models/pet_mood.dart';
import '../models/pet_state.dart';
import '../pet_constants.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(ref.watch(localStoreProvider));
});

class PetNotifier extends AsyncNotifier<PetState> {
  @override
  Future<PetState> build() {
    return ref.watch(petRepositoryProvider).getState();
  }

  Future<void> registerDrinkLogged({required int totalMlToday}) async {
    final repo = ref.read(petRepositoryProvider);
    final current = state.value ?? const PetState();

    var next = current.copyWith(points: current.points + kPointsPerDrink);

    if (totalMlToday >= kDailyGoalMl) {
      final today = _isoDate(DateTime.now());
      if (current.lastGoalMetDate != today) {
        final yesterday = _isoDate(DateTime.now().subtract(const Duration(days: 1)));
        final newStreak =
            current.lastGoalMetDate == yesterday ? current.currentStreak + 1 : 1;

        next = next.copyWith(
          points: next.points + kDailyGoalBonusPoints,
          currentStreak: newStreak,
          longestStreak: newStreak > current.longestStreak ? newStreak : current.longestStreak,
          lastGoalMetDate: today,
        );
      }
    }

    state = AsyncValue.data(next);
    await repo.saveState(next);
  }

  Future<void> unlockItem(ShopItem item) async {
    final current = state.value ?? const PetState();
    if (current.unlockedItemIds.contains(item.id) || current.points < item.cost) {
      return;
    }

    final next = current.copyWith(
      points: current.points - item.cost,
      unlockedItemIds: {...current.unlockedItemIds, item.id},
    );

    state = AsyncValue.data(next);
    await ref.read(petRepositoryProvider).saveState(next);
  }

  Future<void> equipItem(String itemId) async {
    final current = state.value ?? const PetState();
    if (!current.unlockedItemIds.contains(itemId)) {
      return;
    }

    final next = current.copyWith(equippedItemId: itemId);
    state = AsyncValue.data(next);
    await ref.read(petRepositoryProvider).saveState(next);
  }

  String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Debug-only helpers for exercising streaks/points without waiting on
  /// real time or real drinks. Callers gate these behind kDebugMode.
  Future<void> debugAdjustPoints(int delta) async {
    final current = state.value ?? const PetState();
    final next = current.copyWith(points: (current.points + delta).clamp(0, 1 << 30));
    state = AsyncValue.data(next);
    await ref.read(petRepositoryProvider).saveState(next);
  }

  Future<void> debugBumpStreak() async {
    final current = state.value ?? const PetState();
    final newStreak = current.currentStreak + 1;
    final yesterday = _isoDate(DateTime.now().subtract(const Duration(days: 1)));

    final next = current.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > current.longestStreak ? newStreak : current.longestStreak,
      lastGoalMetDate: yesterday,
    );
    state = AsyncValue.data(next);
    await ref.read(petRepositoryProvider).saveState(next);
  }

  Future<void> debugReset() async {
    const fresh = PetState();
    state = const AsyncValue.data(fresh);
    await ref.read(petRepositoryProvider).saveState(fresh);
  }
}

final petStateProvider = AsyncNotifierProvider<PetNotifier, PetState>(PetNotifier.new);

/// Ticks once a minute so petMoodProvider re-evaluates as time passes, even
/// without a new drink being logged.
final _moodTickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(minutes: 1), (i) => i);
});

final petMoodProvider = Provider<PetMood>((ref) {
  ref.watch(_moodTickProvider);
  final lastDrinkAt = ref.watch(lastDrinkAtProvider).value;
  return PetMood.fromLastDrinkAt(lastDrinkAt);
});
