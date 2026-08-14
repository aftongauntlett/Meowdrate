import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../flood/providers/flood_providers.dart';
import '../../hydration/models/hydration_entry.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../providers/theme_mode_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeModeAsync = ref.watch(themeModeProvider);
    final floodAsync = ref.watch(floodStateProvider);
    final summaryAsync = ref.watch(hydrationSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Appearance',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Changes the app\'s colors, not the flood scene — that shifts with '
            'the time of day on its own.',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          themeModeAsync.when(
            data: (mode) => SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Consistency',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.sm),
          floodAsync.when(
            data: (flood) => _StreakChip(streak: flood.currentStreak),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Deliberately kept off the main screen — the goal is better '
            'habits, not a number to keep feeding.',
            style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Recent',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.sm),
          summaryAsync.when(
            data: (summary) => _RecentList(entries: summary.recent),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Credits',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cat sprites by toffeecraft (toffeecraft.itch.io/cat-pack).',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '"Stars & Sines" by Xcreenplay (freesound.org/s/536023), '
            'licensed CC BY-NC 4.0.',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'About your data',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No accounts, no cloud, nothing tracked. Everything lives on your '
            'phone. If you switch phones or reinstall, your progress starts '
            'over. That\'s the tradeoff for keeping this free and private.',
            style: TextStyle(color: colors.textMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          streak == 0 ? 'No days in a row yet' : '$streak day${streak == 1 ? '' : 's'} in a row',
          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.entries});

  final List<HydrationEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: entries.isEmpty
          ? Text('No drinks yet.', style: TextStyle(color: colors.textMuted))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${_formatTime(entry.timestamp)} • ${entry.amountMl} ml',
                        style: TextStyle(color: colors.textMuted, fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  String _formatTime(int timestampMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
