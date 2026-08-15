import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hydration/hydration_constants.dart';
import '../../hydration/providers/hydration_providers.dart';

const _storageKey = 'settings.dailyGoalGlasses.v1';

const kDefaultDailyGoalGlasses = 7;
const kMinDailyGoalGlasses = 1;
const kMaxDailyGoalGlasses = 15;

/// How many drinks make up "today's" goal — the flood/streak/progress
/// display all key off this rather than a raw ml number. Mood art doesn't
/// need to track it 1:1: the cat's three moods are driven by the flood's
/// *fraction* drained, not by glass count, so this works the same whether
/// the goal is 1 glass or 15.
class DailyGoalNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final store = ref.watch(localStoreProvider);
    final json = await store.readJson(_storageKey);
    final stored = json?['glasses'] as int?;
    if (stored == null) {
      return kDefaultDailyGoalGlasses;
    }
    return stored.clamp(kMinDailyGoalGlasses, kMaxDailyGoalGlasses);
  }

  Future<void> set(int glasses) async {
    final clamped = glasses.clamp(kMinDailyGoalGlasses, kMaxDailyGoalGlasses);
    state = AsyncValue.data(clamped);
    await ref.read(localStoreProvider).writeJson(_storageKey, {'glasses': clamped});
  }
}

final dailyGoalGlassesProvider =
    AsyncNotifierProvider<DailyGoalNotifier, int>(DailyGoalNotifier.new);

/// Today's goal in ml — the unit the flood level and streak comparison
/// actually need. Falls back to the default glass count while the stored
/// preference is still loading, same pattern as floodLevelProvider falling
/// back to 0 while today's hydration total is still loading.
final dailyGoalMlProvider = Provider<int>((ref) {
  final glasses = ref.watch(dailyGoalGlassesProvider).value ?? kDefaultDailyGoalGlasses;
  return glasses * kDrinkAmountMl;
});
