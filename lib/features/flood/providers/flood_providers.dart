import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_effect.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/utils/iso_date.dart';
import '../../hydration/hydration_constants.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../data/flood_repository.dart';
import '../models/flood_state.dart';

final floodRepositoryProvider = Provider<FloodRepository>((ref) {
  return FloodRepository(ref.watch(localStoreProvider));
});

/// A one-shot narrator-worthy event noticed while catching up on missed
/// days. Never persisted — it's consumed once by the UI (see
/// FloodNotifier.consumePendingRolloverEvent) and then forgotten, same as
/// every other "today" concept in this app.
enum DayRolloverEvent { none, goalMissed, longAbsence }

/// Debug-only: pins the flood level instead of deriving it from today's
/// hydration total.
class DebugFloodLevelOverride extends Notifier<double?> {
  @override
  double? build() => null;

  void setOverride(double? value) => state = value;
}

final debugFloodLevelOverrideProvider =
    NotifierProvider<DebugFloodLevelOverride, double?>(DebugFloodLevelOverride.new);

/// 1.0 (fully flooded) down to 0.0 (fully drained) — derived live from
/// today's hydration total, never persisted, so there's no "today" state
/// to lose.
final floodLevelProvider = Provider<double>((ref) {
  final override = ref.watch(debugFloodLevelOverrideProvider);
  if (override != null) {
    return override.clamp(0.0, 1.0);
  }

  final totalMl = ref.watch(hydrationSummaryProvider).value?.totalAmountMl ?? 0;
  final progress = (totalMl / kDailyGoalMl).clamp(0.0, 1.0);
  return 1.0 - progress;
});

class FloodNotifier extends AsyncNotifier<FloodState> {
  DayRolloverEvent _pendingRolloverEvent = DayRolloverEvent.none;

  @override
  Future<FloodState> build() async {
    final repo = ref.watch(floodRepositoryProvider);
    final loaded = await repo.getState();
    final now = DateTime.now();

    if (loaded.lastSeenDate != isoDate(now)) {
      _pendingRolloverEvent = _classifyRollover(loaded, now);
    }

    final corrected = _applyDayRollover(loaded, now);
    if (!identical(corrected, loaded)) {
      await repo.saveState(corrected);
    }
    return corrected;
  }

  /// Returns whatever narrator-worthy event was noticed on this app open
  /// (missed goal, long absence, or none), then clears it so it only
  /// surfaces once per session.
  DayRolloverEvent consumePendingRolloverEvent() {
    final event = _pendingRolloverEvent;
    _pendingRolloverEvent = DayRolloverEvent.none;
    return event;
  }

  Future<void> registerDrinkLogged({required int totalMlToday}) async {
    final repo = ref.read(floodRepositoryProvider);
    final current = state.value ?? const FloodState();
    final today = isoDate(DateTime.now());

    var next = current.copyWith(
      lastSeenDate: today,
      lifetimeCups: current.lifetimeCups + 1,
    );

    if (totalMlToday >= kDailyGoalMl && current.lastGoalMetDate != today) {
      final yesterday = isoDate(DateTime.now().subtract(const Duration(days: 1)));
      final newStreak =
          current.lastGoalMetDate == yesterday ? current.currentStreak + 1 : 1;

      next = next.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > current.longestStreak ? newStreak : current.longestStreak,
        lastGoalMetDate: today,
      );
      unawaited(ref.read(soundServiceProvider).play(SoundEffect.goalMet));
    }

    state = AsyncValue.data(next);
    await repo.saveState(next);
  }

  /// Quietly zeroes the streak if a day passed without the goal being met —
  /// no punishment screen, the number just reflects reality next time the
  /// app is opened. Returns the loaded state unchanged (same reference) if
  /// today was already checked.
  FloodState _applyDayRollover(FloodState current, DateTime now) {
    final today = isoDate(now);
    if (current.lastSeenDate == today) {
      return current;
    }

    final yesterday = isoDate(now.subtract(const Duration(days: 1)));
    final streakBroken = current.currentStreak > 0 &&
        current.lastGoalMetDate != today &&
        current.lastGoalMetDate != yesterday;

    return current.copyWith(
      lastSeenDate: today,
      currentStreak: streakBroken ? 0 : current.currentStreak,
    );
  }

  /// Long absence (>3 days) takes priority over a plain missed goal, since
  /// by then the day-to-day streak state isn't really the point anymore.
  DayRolloverEvent _classifyRollover(FloodState current, DateTime now) {
    final lastSeen = current.lastSeenDate;
    if (lastSeen == null) {
      return DayRolloverEvent.none;
    }

    final gapDays = _daysBetween(lastSeen, now);
    if (gapDays <= 0) {
      return DayRolloverEvent.none;
    }
    if (gapDays > 3) {
      return DayRolloverEvent.longAbsence;
    }

    final today = isoDate(now);
    final yesterday = isoDate(now.subtract(const Duration(days: 1)));
    final goalMetRecently =
        current.lastGoalMetDate == today || current.lastGoalMetDate == yesterday;
    return goalMetRecently ? DayRolloverEvent.none : DayRolloverEvent.goalMissed;
  }

  int _daysBetween(String isoDateStr, DateTime now) {
    final parts = isoDateStr.split('-').map(int.parse).toList();
    final then = DateTime(parts[0], parts[1], parts[2]);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(then).inDays;
  }

  /// Debug-only helpers for exercising streaks without waiting on real
  /// time. Callers gate these behind kDebugMode.
  Future<void> debugBumpStreak() async {
    final current = state.value ?? const FloodState();
    final newStreak = current.currentStreak + 1;
    final yesterday = isoDate(DateTime.now().subtract(const Duration(days: 1)));

    final next = current.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > current.longestStreak ? newStreak : current.longestStreak,
      lastGoalMetDate: yesterday,
    );
    state = AsyncValue.data(next);
    await ref.read(floodRepositoryProvider).saveState(next);
  }

  Future<void> debugReset() async {
    const fresh = FloodState();
    state = const AsyncValue.data(fresh);
    await ref.read(floodRepositoryProvider).saveState(fresh);
  }
}

final floodStateProvider = AsyncNotifierProvider<FloodNotifier, FloodState>(FloodNotifier.new);
