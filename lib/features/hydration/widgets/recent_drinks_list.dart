import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/pixel_icon.dart';
import '../../../core/widgets/themed_card_decoration.dart';
import '../models/hydration_entry.dart';

/// Every one of today's logged drinks, most recent first, reset daily
/// along with the rest of "today" (see HydrationRepository's 2am day
/// boundary). Laid out as a vertical timeline rather than a wrapping row
/// of "drop + clock time" chips — each entry gets the same check glyph
/// that confirms "I Meowdrated!" in the Drink Moment flow (icon_check.png,
/// same asset, same meaning: this one's done), strung together by a
/// primary-tinted trail instead of a plain divider, so it reads as a
/// little quest log rather than a spreadsheet. Each row's clock time
/// ("3:45 PM") is pushed to a quiet trailing label — useful, but no
/// longer the headline. Unbounded in count — once a day's
/// worth of entries is taller than fits comfortably, the card scrolls
/// internally (a fixed max height) rather than growing and pushing the
/// rest of the home screen down the page.
class RecentDrinksList extends StatelessWidget {
  const RecentDrinksList({super.key, required this.entries});

  final List<HydrationEntry> entries;

  // Taller than the old chip-wrap cap (220) — timeline rows are bigger
  // than chips, and a taller card is also most of the fix for the empty
  // space this replaced: a handful of entries now reads as a real card
  // instead of a sliver hugging the "Recent" label.
  static const _maxListHeight = 340.0;

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
              child: SingleChildScrollView(child: _Timeline(entries: entries)),
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

class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries});

  final List<HydrationEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isLast,
  });

  final HydrationEntry entry;
  final bool isLast;

  static const _nodeSize = 30.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: _nodeSize,
                height: _nodeSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: PixelIcon(
                  'assets/ui/icon_check.png',
                  color: colors.primary,
                  size: 15,
                ),
              ),
              // Trail between nodes, not the same faint divider used
              // elsewhere — tinted with the primary "water" color so a
              // stack of entries reads as a connected trail of drinks
              // rather than a generic bulleted list.
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: colors.primary.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              // Bottom breathing room (not just AppSpacing.sm) gives the
              // connector trail on the left enough length to actually
              // read as a line rather than a stray dot between nodes.
              padding: EdgeInsets.only(
                top: 4,
                bottom: isLast ? 0 : AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meowdrated',
                          style: TextStyle(
                            fontFamily: kHeadingFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _clockTime(entry.timestamp),
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // RetroCatsPaid's water bowl (CatRoomDecorations.png,
                  // light-blue variant) — same pack as the Settings peek
                  // cats, at native color like the other fixed game-art
                  // pieces (btn_pill_blue.png, panel_card.png) rather than
                  // tinted via PixelIcon.
                  Image.asset(
                    'assets/ui/water_bowl.png',
                    width: 32,
                    filterQuality: FilterQuality.none,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _clockTime(int timestampMs) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final hour24 = date.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = hour24 < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}
