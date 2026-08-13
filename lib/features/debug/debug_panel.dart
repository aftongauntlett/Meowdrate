import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../hydration/hydration_constants.dart';
import '../hydration/providers/hydration_providers.dart';
import '../pet/providers/pet_providers.dart';

/// Debug-only shortcuts for exercising streaks/points/moods without waiting
/// on real time. Only ever shown behind kDebugMode — see home_screen.dart.
class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(hydrationControllerProvider);
    final petNotifier = ref.read(petStateProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug panel',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Debug-only — never shown in a release build.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                  label: 'Simulate thirsty (4h ago)',
                  onPressed: () => controller.debugLogBackdated(const Duration(hours: 4)),
                ),
                _DebugButton(
                  label: '+100 points',
                  onPressed: () => petNotifier.debugAdjustPoints(100),
                ),
                _DebugButton(
                  label: '-100 points',
                  onPressed: () => petNotifier.debugAdjustPoints(-100),
                ),
                _DebugButton(
                  label: '+1 day streak',
                  onPressed: () => petNotifier.debugBumpStreak(),
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
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDestructive ? Colors.redAccent : AppColors.text,
        side: BorderSide(color: isDestructive ? Colors.redAccent : AppColors.border),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
