import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_effect.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/home_widget/home_widget_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/slide_up_route.dart';
import '../../debug/debug_panel.dart';
import '../../hydration/models/hydration_entry.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../../hydration/screens/drink_moment_screen.dart';
import '../../hydration/widgets/recent_drinks_list.dart';
import '../../narrator/narrator_selector.dart';
import '../../narrator/narrator_trigger.dart';
import '../../narrator/providers/narrator_providers.dart';
import '../../reminders/reminder_coordinator.dart';
import '../../settings/providers/daily_goal_providers.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/flood_providers.dart';
import '../widgets/flood_scene.dart';

class FloodHomeScreen extends ConsumerStatefulWidget {
  const FloodHomeScreen({super.key});

  @override
  ConsumerState<FloodHomeScreen> createState() => _FloodHomeScreenState();
}

class _FloodHomeScreenState extends ConsumerState<FloodHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkRolloverEvent();
    // Reminders are single-shot, not daily-repeating (see ReminderService),
    // so if the app was closed across a day rollover — or the last batch
    // simply ran out — this is what notices and schedules the next run.
    unawaited(
      ref.read(reminderCoordinatorProvider).reconcile().catchError((_) {
        // Notifications aren't available on this platform/environment.
      }),
    );
    // Also covers the day rolling over while the app was closed — the
    // widget would otherwise show yesterday's count until the OS's next
    // ~30min refresh tick.
    unawaited(
      ref.read(homeWidgetSyncServiceProvider).sync().catchError((_) {
        // Home-screen widgets aren't available on this platform/environment.
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Fires on genuine foreground transitions (unminimized, switched back
  // to, unlocked) — not on cold launch, since Flutter only calls this on a
  // *change* of lifecycle state. Cold launch's greeting is handled by
  // _checkRolloverEvent from initState instead.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(openingLineOverrideProvider.notifier)
          .set(selectNarratorLine(NarratorTrigger.appReturn));
    }
  }

  /// Sets today's opening caption: a goal-missed/long-absence line if the
  /// app noticed one while catching up on missed days, otherwise a plain
  /// "welcome back" line — either way, a greeting rather than a rerun of
  /// whatever drink-logged line was showing when the app was last closed.
  Future<void> _checkRolloverEvent() async {
    await ref.read(floodStateProvider.future);
    if (!mounted) {
      return;
    }

    final event = ref
        .read(floodStateProvider.notifier)
        .consumePendingRolloverEvent();
    final trigger = switch (event) {
      DayRolloverEvent.goalMissed => NarratorTrigger.goalMissed,
      DayRolloverEvent.longAbsence => NarratorTrigger.longAbsence,
      DayRolloverEvent.none => NarratorTrigger.appReturn,
    };

    ref
        .read(openingLineOverrideProvider.notifier)
        .set(selectNarratorLine(trigger));
  }

  Future<void> _openDrinkMoment() async {
    unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTap));
    // Slides up like the Settings sheet, rather than the platform-default
    // horizontal push — the two full-screen overlays in this app should
    // feel like the same kind of thing entering.
    final logged = await Navigator.of(context)
        .push<bool>(SlideUpRoute(builder: (_) => const DrinkMomentScreen()));
    // The flood scene's own caption already updates the moment a drink is
    // logged, so there's no separate confirmation toast here — but the
    // greeting override has to step aside first, or it'd keep showing
    // instead of that drink's own reaction line.
    if (logged ?? false) {
      ref.read(openingLineOverrideProvider.notifier).set(null);
    }
  }

  void _openDebugPanel() {
    unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTap));
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      // Scroll-controlled + height-capped: the button list is tall enough
      // to overflow (and, uncapped, to cover the flood scene above it),
      // which made "Next narrator line" look like a no-op — the state was
      // updating, just hidden behind the sheet.
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (_) => const DebugPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final summaryAsync = ref.watch(hydrationSummaryProvider);
    final goalGlasses =
        ref.watch(dailyGoalGlassesProvider).value ?? kDefaultDailyGoalGlasses;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(hydrationSummaryProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl)
                .copyWith(top: AppSpacing.md, bottom: AppSpacing.xxl),
            children: [
              // No app-name navbar — the flood scene is the screen, same as
              // how Finch/Focus Friend never re-announce their own name
              // once you're past the home screen icon. Settings (and, in
              // debug builds, the debug panel) live as small icon overlays
              // in the scene's corners instead of a chrome bar above it.
              Stack(
                children: [
                  const FloodScene(),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _SceneCornerButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onPressed: () {
                        unawaited(
                          ref
                              .read(soundServiceProvider)
                              .play(SoundEffect.uiTap),
                        );
                        showSettingsSheet(context);
                      },
                    ),
                  ),
                  if (kDebugMode)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _SceneCornerButton(
                        icon: Icons.bug_report_outlined,
                        tooltip: 'Debug panel',
                        onPressed: _openDebugPanel,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              summaryAsync.when(
                data: (summary) =>
                    _GlassCounter(summary: summary, goalGlasses: goalGlasses),
                loading: () => _GlassCounter(
                  summary: DrinksTodaySummary.empty,
                  goalGlasses: goalGlasses,
                ),
                error: (_, _) => _GlassCounter(
                  summary: DrinksTodaySummary.empty,
                  goalGlasses: goalGlasses,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                // A Row (not Center) is what actually hugs the button to its
                // content width here — PixelButton's inner Container sets
                // `alignment: Alignment.center`, which makes it expand to
                // fill any *bounded* incoming constraint (Center's included,
                // even though it's loose). Only a Row gives its non-flex
                // child an *unbounded* main-axis constraint, which is what
                // lets the Container shrink-wrap instead — same reason the
                // Appearance chips below already hug their text.
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PixelButton(
                    onPressed: _openDrinkMoment,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // A plain glyph (icon_plus.png) read as a smudge/dot
                        // at this size once recolored solid white — a
                        // recognizable water drop reads instantly as "drink."
                        const Icon(
                          Icons.water_drop,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Meowdrate!'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Recent',
                style: const TextStyle(
                  fontFamily: kHeadingFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ).copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              summaryAsync.when(
                data: (summary) => RecentDrinksList(entries: summary.recent),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A HUD-style icon button meant to sit directly on top of the flood
/// scene's sky — the sky's color shifts with time of day, so unlike the
/// bare standalone icons elsewhere, this one keeps a small dark scrim
/// behind it for guaranteed legibility against a background we don't
/// control the color of.
class _SceneCornerButton extends StatelessWidget {
  const _SceneCornerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        iconSize: 24,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _GlassCounter extends StatelessWidget {
  const _GlassCounter({required this.summary, required this.goalGlasses});

  final DrinksTodaySummary summary;
  final int goalGlasses;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '${summary.count} / $goalGlasses glasses today',
        style: TextStyle(
          color: context.colors.textMuted,
          fontFamily: kHeadingFontFamily,
          fontSize: 13,
        ),
      ),
    );
  }
}
