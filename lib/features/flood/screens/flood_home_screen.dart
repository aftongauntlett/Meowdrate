import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../debug/debug_panel.dart';
import '../../hydration/hydration_constants.dart';
import '../../hydration/models/hydration_entry.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../../hydration/screens/drink_moment_screen.dart';
import '../../narrator/narrator_selector.dart';
import '../../narrator/narrator_trigger.dart';
import '../../narrator/providers/narrator_providers.dart';
import '../../reminders/reminder_service.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/flood_providers.dart';
import '../widgets/flood_scene.dart';

class FloodHomeScreen extends ConsumerStatefulWidget {
  const FloodHomeScreen({super.key});

  @override
  ConsumerState<FloodHomeScreen> createState() => _FloodHomeScreenState();
}

class _FloodHomeScreenState extends ConsumerState<FloodHomeScreen> {
  bool _remindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _syncReminderState();
    _checkRolloverEvent();
  }

  /// If the app noticed a missed goal or a long absence while catching up
  /// on missed days, that line becomes today's opening caption in the
  /// flood scene itself — no separate popup.
  Future<void> _checkRolloverEvent() async {
    await ref.read(floodStateProvider.future);
    if (!mounted) {
      return;
    }

    final event = ref.read(floodStateProvider.notifier).consumePendingRolloverEvent();
    final trigger = switch (event) {
      DayRolloverEvent.goalMissed => NarratorTrigger.goalMissed,
      DayRolloverEvent.longAbsence => NarratorTrigger.longAbsence,
      DayRolloverEvent.none => null,
    };

    ref
        .read(openingLineOverrideProvider.notifier)
        .set(trigger == null ? null : selectNarratorLine(trigger));
  }

  Future<void> _syncReminderState() async {
    try {
      final pending = await reminderService.pending();
      if (!mounted) {
        return;
      }
      setState(() => _remindersEnabled = pending.isNotEmpty);
    } catch (_) {
      // Notifications aren't available on this platform/environment.
    }
  }

  Future<void> _toggleReminders() async {
    try {
      if (_remindersEnabled) {
        await reminderService.cancelReminders();
        setState(() => _remindersEnabled = false);
        return;
      }

      final granted = await reminderService.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission was denied.')),
        );
        return;
      }

      await reminderService.scheduleHourlyReminder();
      setState(() => _remindersEnabled = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminders aren’t available on this platform.')),
      );
    }
  }

  Future<void> _openDrinkMoment() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DrinkMomentScreen()),
    );
    // The flood scene's own caption already updates the moment a drink is
    // logged, so there's no separate confirmation toast here.
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openDebugPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (_) => const DebugPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final summaryAsync = ref.watch(hydrationSummaryProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(hydrationSummaryProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(
              top: AppSpacing.xl,
              bottom: AppSpacing.xxl,
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Water Buddy',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Row(
                    children: [
                      if (kDebugMode)
                        IconButton(
                          tooltip: 'Debug panel',
                          onPressed: _openDebugPanel,
                          icon: Icon(Icons.bug_report_outlined, color: colors.textMuted),
                        ),
                      IconButton(
                        tooltip: _remindersEnabled ? 'Reminders on' : 'Reminders off',
                        onPressed: _toggleReminders,
                        icon: Icon(
                          _remindersEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                          color: _remindersEnabled ? colors.primary : colors.textMuted,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: _openSettings,
                        icon: Icon(Icons.settings_outlined, color: colors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const FloodScene(),
              const SizedBox(height: AppSpacing.sm),
              summaryAsync.when(
                data: (summary) => _MlCounter(summary: summary),
                loading: () => const _MlCounter(summary: DrinksTodaySummary.empty),
                error: (_, _) => const _MlCounter(summary: DrinksTodaySummary.empty),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openDrinkMoment,
                  child: const Text('Log a drink'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MlCounter extends StatelessWidget {
  const _MlCounter({required this.summary});

  final DrinksTodaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '${summary.totalAmountMl} / $kDailyGoalMl ml · ${summary.count} drinks today',
        style: TextStyle(color: context.colors.textMuted, fontSize: 13),
      ),
    );
  }
}

