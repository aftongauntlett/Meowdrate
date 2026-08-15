import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/audio/sound_effect.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_icon.dart';
import '../../../core/widgets/themed_card_decoration.dart';
import '../../flood/providers/flood_providers.dart';
import '../../hydration/providers/hydration_providers.dart';
import '../../reminders/reminder_coordinator.dart';
import '../../reminders/reminder_service.dart';
import '../providers/daily_goal_providers.dart';
import '../providers/reminders_enabled_providers.dart';
import '../providers/settings_sheet_providers.dart';
import '../providers/theme_mode_providers.dart';

/// Settings opens as a modal sheet you dismiss, not a page you navigate
/// back from — there's no deeper drill-down inside it, so a stacked route
/// with a back button was the wrong metaphor.
///
/// The flood scene underneath stays mounted the whole time
/// (`showModalBottomSheet` doesn't remove it), so settingsSheetOpenProvider
/// is flipped on for the sheet's lifetime — see its doc comment for why.
Future<void> showSettingsSheet(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  container.read(settingsSheetOpenProvider.notifier).set(true);
  try {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SettingsSheet(),
    );
  } finally {
    container.read(settingsSheetOpenProvider.notifier).set(false);
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    // Inset on the sides/bottom only, not the top — this is meant to sit
    // flush against the very top of the screen (overlapping where the
    // gear icon lives on the home screen underneath), while still reading
    // as a card floating over the scene at the bottom, dimmed backdrop
    // visible around it there.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      child: ThemedCard(
        // No FractionallySizedBox here on purpose: a Column defaults to
        // MainAxisSize.max, so left to size itself against the modal
        // route's own (already safe-area-bounded) height constraint, it
        // naturally fills all the way to the top instead of leaving a gap
        // there — which is what made this read as "not top aligned."
        radius: 24,
        child: Column(
          children: [
            const SizedBox(height: 22),
            SizedBox(
              // Width must be explicit too, not just height — the Column
              // wrapping this doesn't stretch its children by default, so
              // without it this box (and the Stack inside) shrink-wraps to
              // the "Settings" text's own width instead of the full header
              // width, which put "right: md" only a few pixels from the
              // text itself rather than the card's actual right edge.
              width: double.infinity,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: colors.text,
                      fontFamily: kHeadingFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.md,
                    child: _CloseButton(
                      onPressed: () {
                        unawaited(
                          ref
                              .read(soundServiceProvider)
                              .play(SoundEffect.uiTapNegative),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: SettingsScreen()),
          ],
        ),
      ),
    );
  }
}

/// A themed close button (the CatUIPaid "x" glyph, same as Drink Moment's
/// Skip) instead of a stock Material [Icons.close] — that read as
/// off-the-shelf "CSS" chrome next to everything else here. Built the same
/// way as [_StepperButton] (GestureDetector + Opacity, no Material ink
/// well) so there's no oversized hover/highlight halo that can overhang
/// the card's edge — the plain [IconButton] this replaces had exactly
/// that problem, since its default 48×48 hit area doesn't fit the
/// available corner padding.
class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: Opacity(
          opacity: _pressed ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: PixelIcon(
              'assets/ui/icon_x.png',
              color: colors.textMuted,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeModeAsync = ref.watch(themeModeProvider);
    final floodAsync = ref.watch(floodStateProvider);
    final dailyGoalAsync = ref.watch(dailyGoalGlassesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _SettingsPanel(
          title: 'Appearance',
          description:
              'Changes the app\'s colors, not the water scene — that shifts with '
              'the time of day on its own.',
          centerChild: true,
          child: themeModeAsync.when(
            data: (mode) => _AppearanceToggle(
              mode: mode,
              onChanged: (value) {
                unawaited(
                  ref.read(soundServiceProvider).play(SoundEffect.uiTap),
                );
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsPanel(
          title: '# of Glasses a Day',
          description:
              'How many glasses make up a full day — the cat is saved once '
              'you\'ve logged this many.',
          centerChild: true,
          child: dailyGoalAsync.when(
            data: (glasses) => _GoalStepper(
              glasses: glasses,
              onChanged: (value) =>
                  ref.read(dailyGoalGlassesProvider.notifier).set(value),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SettingsPanel(
          title: 'Reminders',
          description:
              'A nudge every few hours between 7am and 10pm — skipped if '
              'you\'ve already logged a drink recently or hit today\'s goal.',
          centerChild: true,
          child: _RemindersSection(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsPanel(
          title: 'Consistency',
          description:
              'Deliberately kept off the main screen — the goal is better '
              'habits, not a number to keep feeding.',
          centerChild: true,
          child: floodAsync.when(
            data: (flood) => _StreakChip(streak: flood.currentStreak),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _SettingsPanel(
              title: 'Credits',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CreditLine(
                    before: 'Cat sprites and UI kit by toffeecraft (',
                    linkText: 'toffeecraft.itch.io/cat-pack',
                    url: 'https://toffeecraft.itch.io/cat-pack',
                    after: ').',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _CreditLine(
                    before: '"Stars & Sines" by Xcreenplay (',
                    linkText: 'freesound.org/s/536023',
                    url: 'https://freesound.org/s/536023',
                    after: '), licensed CC BY-NC 4.0.',
                  ),
                ],
              ),
            ),
            // A small cat peeking over the card's edge — the one purely
            // decorative touch in this sheet, kept to a single spot rather
            // than scattered everywhere.
            Positioned(
              right: 12,
              bottom: -14,
              child: Image.asset(
                'assets/ui/sleeping_cat.png',
                width: 40,
                filterQuality: FilterQuality.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsPanel(
          title: 'Support this app',
          description:
              "Built solo by a developer who struggles with drinking water "
              "too. It's free to use — if it's helped you out, support is "
              "always appreciated.",
          child: SizedBox(
            width: double.infinity,
            child: PixelButton(
              onPressed: () {
                unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTap));
                unawaited(
                  launchUrl(
                    Uri.parse('https://ko-fi.com/prettyprettyprettygood'),
                    mode: LaunchMode.externalApplication,
                  ),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 16),
                  SizedBox(width: AppSpacing.xs),
                  Text('Support on Ko-fi'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsPanel(
          title: 'About your data',
          child: Text(
            'No accounts, no cloud, nothing tracked. Everything lives on your '
            'phone. If you switch phones or reinstall, your progress starts '
            'over. That\'s the tradeoff for keeping this free and private.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SettingsPanel(
          title: 'Reset local data',
          description:
              'Clears everything logged today and fills the water back '
              'up — your streak and past days are untouched.',
          child: _ResetTodayButton(),
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.title,
    this.description,
    this.centerChild = false,
    required this.child,
  });

  final String title;
  final String? description;

  /// Centers [child] within the panel's full width — used for the actual
  /// interactive controls (toggles, steppers) so they sit in the middle of
  /// the card, while [title]/[description] stay left-aligned as body text.
  final bool centerChild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ThemedCard(
      width: double.infinity,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        26,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontFamily: kHeadingFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          centerChild
              ? SizedBox(
                  width: double.infinity,
                  child: Center(child: child),
                )
              : child,
        ],
      ),
    );
  }
}

/// A credit line with a tappable URL segment in the middle, opened in the
/// device's browser rather than in-app — these are attribution links, not
/// app content worth building a webview for.
class _CreditLine extends StatelessWidget {
  const _CreditLine({
    required this.before,
    required this.linkText,
    required this.url,
    required this.after,
  });

  final String before;
  final String linkText;
  final String url;
  final String after;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseStyle = TextStyle(color: colors.textMuted, fontSize: 13);
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: linkText,
            style: TextStyle(
              color: colors.accent,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

class _AppearanceToggle extends StatelessWidget {
  const _AppearanceToggle({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AppearanceChip(
          label: 'System',
          icon: Icons.brightness_auto,
          selected: mode == ThemeMode.system,
          onPressed: () => onChanged(ThemeMode.system),
        ),
        const SizedBox(width: AppSpacing.sm),
        _AppearanceChip(
          label: 'Light',
          icon: Icons.light_mode,
          selected: mode == ThemeMode.light,
          onPressed: () => onChanged(ThemeMode.light),
        ),
        const SizedBox(width: AppSpacing.sm),
        _AppearanceChip(
          label: 'Dark',
          icon: Icons.dark_mode,
          selected: mode == ThemeMode.dark,
          onPressed: () => onChanged(ThemeMode.dark),
        ),
      ],
    );
  }
}

class _AppearanceChip extends StatelessWidget {
  const _AppearanceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PixelButton(
      height: 44,
      // Always tappable (even the already-selected chip) — dimming, not a
      // disabled state, is what signals "not selected."
      onPressed: onPressed,
      muted: !selected,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      ),
    );
  }
}

class _GoalStepper extends ConsumerWidget {
  const _GoalStepper({required this.glasses, required this.onChanged});

  final int glasses;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          assetPath: 'assets/ui/icon_button_minus.png',
          onPressed: glasses > kMinDailyGoalGlasses
              ? () {
                  unawaited(
                    ref
                        .read(soundServiceProvider)
                        .play(SoundEffect.uiTapNegative),
                  );
                  onChanged(glasses - 1);
                }
              : null,
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$glasses',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.text,
              fontFamily: kHeadingFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
        _StepperButton(
          assetPath: 'assets/ui/icon_button_plus.png',
          onPressed: glasses < kMaxDailyGoalGlasses
              ? () {
                  unawaited(
                    ref.read(soundServiceProvider).play(SoundEffect.uiTap),
                  );
                  onChanged(glasses + 1);
                }
              : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.assetPath, required this.onPressed});

  final String assetPath;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    // The asset already is a small rounded-square button (background,
    // border and glyph baked in as one piece) — no Material/InkWell circle
    // needed on top of it, that was the "CSS-drawn" chrome that made the
    // bare-glyph version look unfinished. MouseRegion alone (no InkWell)
    // still gets it the pointer-on-hover cursor the other buttons have.
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onPressed,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Image.asset(
            assetPath,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
        ),
      ),
    );
  }
}

/// Owns the reminders on/off toggle itself (moved here from the home
/// screen's bell icon — see FloodHomeScreen). The active window and cadence
/// are fixed (see reminder_service.dart) rather than user-configurable —
/// one less decision, and it keeps this panel to a single control.
class _RemindersSection extends ConsumerWidget {
  const _RemindersSection();

  Future<void> _toggle(WidgetRef ref, BuildContext context, bool value) async {
    unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTap));
    if (!value) {
      await reminderService.cancelReminders();
      await ref.read(remindersEnabledProvider.notifier).set(false);
      return;
    }

    final granted = await reminderService.requestPermission();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission was denied.')),
        );
      }
      return;
    }

    await ref.read(remindersEnabledProvider.notifier).set(true);
    try {
      await ref.read(reminderCoordinatorProvider).reconcile();
    } catch (_) {
      // Notifications aren't available on this platform/environment.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(remindersEnabledProvider).value ?? false;

    // Same pill-chip language as the Appearance toggle above (a PixelButton
    // pair, one dimmed) instead of a stock Material Switch — the Switch was
    // the one control on this sheet that didn't look like it belonged to
    // the same UI kit as everything else.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelButton(
          height: 44,
          onPressed: () => _toggle(ref, context, false),
          muted: enabled,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.notifications_off_outlined, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text('Off'),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        PixelButton(
          height: 44,
          onPressed: () => _toggle(ref, context, true),
          muted: !enabled,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.notifications_active_outlined, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text('On'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Clears today's logged drinks (see [HydrationController.resetToday]) —
/// yesterday and earlier, and the streak, are untouched. Gated behind the
/// same YES/NO cat dialog the debug panel's full reset uses.
class _ResetTodayButton extends ConsumerWidget {
  const _ResetTodayButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: PixelButton(
        onPressed: () async {
          unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTap));
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => const ConfirmDialog(),
          );
          if (confirmed == true) {
            await ref.read(hydrationControllerProvider).resetToday();
          }
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restart_alt, size: 16),
            SizedBox(width: AppSpacing.xs),
            Text('Reset today\'s progress'),
          ],
        ),
      ),
    );
  }
}

// A plain icon + label instead of the earlier translucent pill — the pill
// drew its own ad-hoc colored-chip style (unrelated to any other element
// on this sheet), which is exactly what read as "out of place." This
// matches how every other panel here shows its value: plain centered
// text in the heading font, no extra chrome.
class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, color: colors.primary, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Text(
          streak == 0
              ? 'No days in a row yet'
              : '$streak day${streak == 1 ? '' : 's'} in a row',
          style: TextStyle(
            color: colors.text,
            fontFamily: kHeadingFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
