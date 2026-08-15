import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hydration/providers/hydration_providers.dart';
import '../settings/providers/daily_goal_providers.dart';
import '../settings/providers/reminders_enabled_providers.dart';
import 'reminder_service.dart';

/// Keeps the pending "drink water" reminders in sync with reality. Local
/// notifications can't check "has the user already had one?" at fire
/// time, so instead this re-derives and reschedules them from scratch
/// every time something that should shift or silence them changes — call
/// [reconcile] after a drink is logged, when reminders are toggled on, and
/// on app open (to catch a day rollover while the app was closed).
class ReminderCoordinator {
  ReminderCoordinator(this._ref);

  final Ref _ref;

  Future<void> reconcile() async {
    final enabled = await _ref.read(remindersEnabledProvider.future);
    if (!enabled) {
      return;
    }

    final summary = await _ref.read(hydrationSummaryProvider.future);
    final goalMl = _ref.read(dailyGoalMlProvider);
    // Today's goal already met — no more nudging until tomorrow, when the
    // next reconcile (app open, or the first drink logged) picks back up.
    if (summary.totalAmountMl >= goalMl) {
      await reminderService.cancelReminders();
      return;
    }

    final lastDrinkAt = await _ref.read(lastDrinkAtProvider.future);
    final now = DateTime.now();
    final loggedToday = lastDrinkAt != null && _isSameDay(lastDrinkAt, now);

    // Count the cadence from the last drink if it was today (so logging
    // one pushes the next nudge out — "the user is remembering on their
    // own"); otherwise from now.
    await reminderService.scheduleNextReminders(loggedToday ? lastDrinkAt : now);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final reminderCoordinatorProvider = Provider((ref) => ReminderCoordinator(ref));
