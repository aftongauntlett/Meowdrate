import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/themed_card_decoration.dart';
import '../models/hydration_entry.dart';

/// Every one of today's logged drinks, most recent first, reset daily
/// along with the rest of "today" (see HydrationRepository's 2am day
/// boundary). Laid out as a wrapping row of compact "drop + time" chips
/// rather than a stacked list — reads more like a tally than a log, and
/// wraps on its own as the day fills up instead of needing an explicit
/// column-filling layout. Unbounded in count — once a day's worth of
/// chips is taller than fits comfortably, the card scrolls internally
/// (a fixed max height) rather than growing and pushing the rest of the
/// home screen down the page.
class RecentDrinksList extends StatelessWidget {
  const RecentDrinksList({super.key, required this.entries});

  final List<HydrationEntry> entries;

  static const _maxListHeight = 220.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ThemedCard(
      radius: 18,
      // Extra top inset, not just AppSpacing.lg all round — the card
      // art's tab decoration sits right at the top edge, so equal padding
      // on all sides still reads as less room above than below (same fix
      // as _SettingsPanel's own top padding).
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 26, AppSpacing.lg, AppSpacing.lg),
      child: entries.isEmpty
          ? _EmptyState(colors: colors)
          : ConstrainedBox(
              // Sizes to content when short; caps and scrolls once the
              // day's drink count grows past what fits.
              constraints: const BoxConstraints(maxHeight: _maxListHeight),
              child: SingleChildScrollView(child: _Entries(entries: entries)),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/ui/sleeping_cat.png',
            width: 64,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('No drinks yet.', style: TextStyle(color: colors.textMuted)),
        ],
      ),
    );
  }
}

class _Entries extends StatelessWidget {
  const _Entries({required this.entries});

  final List<HydrationEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_rounded, size: 14, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatTime(entry.timestamp),
                style: TextStyle(
                  color: colors.textMuted,
                  fontFamily: kHeadingFontFamily,
                  fontSize: 14,
                ),
              ),
            ],
          ),
      ],
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
