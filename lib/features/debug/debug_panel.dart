import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/time_of_day/providers/time_of_day_providers.dart';
import '../creatures/creature_roster.dart';
import '../creatures/providers/creature_providers.dart';
import '../flood/providers/flood_providers.dart';
import '../hydration/hydration_constants.dart';
import '../hydration/providers/hydration_providers.dart';
import '../narrator/data/drink_logged_lines.dart';
import '../narrator/narrator_selector.dart';
import '../narrator/narrator_trigger.dart';
import '../narrator/providers/narrator_providers.dart';

/// Debug-only shortcuts for exercising streaks/flood-level/creatures/
/// narrator lines without waiting on real time or real drinks. Only ever
/// shown behind kDebugMode — see flood_home_screen.dart.
class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final controller = ref.read(hydrationControllerProvider);
    final floodNotifier = ref.read(floodStateProvider.notifier);
    final floodLevelOverride = ref.read(debugFloodLevelOverrideProvider.notifier);
    final creatureIndexOverride = ref.read(debugCreatureIndexOverrideProvider.notifier);
    final currentCreatureIndex = ref.watch(debugCreatureIndexOverrideProvider);
    final narratorOccurrenceOverride = ref.read(debugNarratorOccurrenceOverrideProvider.notifier);
    final currentNarratorOccurrence = ref.watch(debugNarratorOccurrenceOverrideProvider);
    final timeOverride = ref.read(debugTimeOverrideProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug panel',
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Debug-only — never shown in a release build.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _DebugButton(
                  label: 'Complete today\'s goal',
                  onPressed: () => controller.logDrink(amountMl: kDailyGoalMl),
                ),
                _DebugButton(
                  label: '+1 day streak',
                  onPressed: () => floodNotifier.debugBumpStreak(),
                ),
                _DebugButton(
                  label: 'Drain flood (0%)',
                  onPressed: () => floodLevelOverride.setOverride(0.0),
                ),
                _DebugButton(
                  label: 'Flood half (50%)',
                  onPressed: () => floodLevelOverride.setOverride(0.5),
                ),
                _DebugButton(
                  label: 'Flood full (100%)',
                  onPressed: () => floodLevelOverride.setOverride(1.0),
                ),
                _DebugButton(
                  label: 'Use real flood level',
                  onPressed: () => floodLevelOverride.setOverride(null),
                ),
                _DebugButton(
                  label: 'Next creature',
                  onPressed: () {
                    final next = ((currentCreatureIndex ?? 0) + 1) % creatureRoster.length;
                    creatureIndexOverride.setOverride(next);
                  },
                ),
                _DebugButton(
                  label: 'Next narrator line',
                  onPressed: () {
                    final next =
                        ((currentNarratorOccurrence ?? 0) % drinkLoggedLines.length) + 1;
                    narratorOccurrenceOverride.setOverride(next);
                  },
                ),
                _DebugButton(
                  label: 'Preview goal-missed line',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(selectNarratorLine(NarratorTrigger.goalMissed))),
                  ),
                ),
                _DebugButton(
                  label: 'Preview long-absence line',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(selectNarratorLine(NarratorTrigger.longAbsence))),
                  ),
                ),
                _DebugButton(
                  label: 'Dawn',
                  onPressed: () => timeOverride.setOverride(6),
                ),
                _DebugButton(
                  label: 'Day',
                  onPressed: () => timeOverride.setOverride(12),
                ),
                _DebugButton(
                  label: 'Dusk',
                  onPressed: () => timeOverride.setOverride(19),
                ),
                _DebugButton(
                  label: 'Night',
                  onPressed: () => timeOverride.setOverride(22),
                ),
                _DebugButton(
                  label: 'Use real time of day',
                  onPressed: () => timeOverride.setOverride(null),
                ),
                _DebugButton(
                  label: 'Reset all local data',
                  isDestructive: true,
                  onPressed: () => controller.debugResetAll(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDestructive ? Colors.redAccent : colors.text,
        side: BorderSide(color: isDestructive ? Colors.redAccent : colors.border),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
