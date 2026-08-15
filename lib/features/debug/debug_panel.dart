import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/sound_effect.dart';
import '../../core/audio/sound_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/time_of_day/providers/time_of_day_providers.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../flood/providers/flood_providers.dart';
import '../hydration/providers/hydration_providers.dart';
import '../narrator/data/drink_logged_lines.dart';
import '../narrator/narrator_selector.dart';
import '../narrator/narrator_trigger.dart';
import '../narrator/providers/narrator_providers.dart';
import '../settings/providers/daily_goal_providers.dart';

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
    final floodLevelOverride = ref.read(
      debugFloodLevelOverrideProvider.notifier,
    );
    final narratorOccurrenceOverride = ref.read(
      debugNarratorOccurrenceOverrideProvider.notifier,
    );
    final currentNarratorOccurrence = ref.watch(
      debugNarratorOccurrenceOverrideProvider,
    );
    final timeOverride = ref.read(debugTimeOverrideProvider.notifier);
    final goalMl = ref.watch(dailyGoalMlProvider);

    return SafeArea(
      child: SingleChildScrollView(
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
                  onPressed: () => controller.logDrink(amountMl: goalMl),
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
                  label: 'Next narrator line',
                  onPressed: () {
                    final next =
                        ((currentNarratorOccurrence ?? 0) %
                            drinkLoggedLines.length) +
                        1;
                    narratorOccurrenceOverride.setOverride(next);
                    // Pops the sheet so the change is actually visible — see
                    // _previewLine's note on why this sheet was hiding the
                    // flood scene it's meant to be previewing.
                    Navigator.of(context).pop();
                  },
                ),
                _DebugButton(
                  label: 'Preview goal-missed line',
                  onPressed: () =>
                      _previewLine(context, ref, NarratorTrigger.goalMissed),
                ),
                _DebugButton(
                  label: 'Preview long-absence line',
                  onPressed: () =>
                      _previewLine(context, ref, NarratorTrigger.longAbsence),
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
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => const ConfirmDialog(),
                    );
                    if (confirmed == true) {
                      controller.debugResetAll();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Routes a goal-missed/long-absence line through the same opening-caption
/// slot the real rollover check uses (see FloodHomeScreen._checkRolloverEvent)
/// — that's the only way those two triggers ever reach the screen, so a
/// debug "preview" needs to go through it too rather than a SnackBar, or it
/// shows up as an unstyled white bar instead of the narrator's actual voice.
/// Also zeroes the drink-count override so the opening-caption branch is
/// the one that wins, and pops the debug sheet so the flood scene underneath
/// is actually visible.
void _previewLine(
  BuildContext context,
  WidgetRef ref,
  NarratorTrigger trigger,
) {
  ref.read(debugNarratorOccurrenceOverrideProvider.notifier).setOverride(0);
  ref
      .read(openingLineOverrideProvider.notifier)
      .set(selectNarratorLine(trigger));
  Navigator.of(context).pop();
}

class _DebugButton extends ConsumerWidget {
  const _DebugButton({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDestructive ? Colors.redAccent : colors.text,
        side: BorderSide(
          color: isDestructive ? Colors.redAccent : colors.border,
        ),
      ),
      onPressed: () {
        unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTap));
        onPressed();
      },
      child: Text(label),
    );
  }
}
