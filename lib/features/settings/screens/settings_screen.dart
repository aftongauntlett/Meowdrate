import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/audio/sound_effect.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_icon.dart';
import '../../../core/widgets/themed_card_decoration.dart';
import '../../flood/providers/flood_providers.dart';
import '../../reminders/reminder_coordinator.dart';
import '../../reminders/reminder_service.dart';
import '../providers/daily_goal_providers.dart';
import '../providers/reminders_enabled_providers.dart';
import '../providers/settings_sheet_providers.dart';
import '../providers/sound_muted_providers.dart';
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
    return Semantics(
      button: true,
      label: 'Close',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: Opacity(
            opacity: _pressed ? 0.6 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: PixelIcon(
                'assets/ui/icon_x.png',
                color: colors.textMuted,
                size: 24,
              ),
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
    final soundMutedAsync = ref.watch(soundMutedProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _PeekPanel(
          side: _PeekSide.left,
          asset: 'assets/ui/cat_sitting_grey.png',
          width: 46,
          bottom: -16,
          panel: _SettingsPanel(
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
        ),
        const SizedBox(height: AppSpacing.lg),
        _PeekPanel(
          side: _PeekSide.right,
          asset: 'assets/ui/cat_stretch_white.png',
          width: 40,
          bottom: -14,
          panel: _SettingsPanel(
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
        ),
        const SizedBox(height: AppSpacing.lg),
        _PeekPanel(
          side: _PeekSide.left,
          asset: 'assets/ui/cat_curled_cream.png',
          width: 54,
          bottom: -16,
          panel: const _SettingsPanel(
            title: 'Reminders',
            description:
                'A nudge every few hours between 7am and 10pm — skipped if '
                'you\'ve already logged a drink recently or hit today\'s goal.',
            centerChild: true,
            child: _RemindersSection(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PeekPanel(
          side: _PeekSide.right,
          asset: 'assets/ui/cat_peekbox_orange.png',
          width: 44,
          bottom: -16,
          panel: _SettingsPanel(
            title: 'Sound',
            description:
                'Mutes everything — sound effects and the Drink Moment '
                'song. For music only, use the speaker icon on the Drink '
                'Moment screen instead.',
            centerChild: true,
            child: soundMutedAsync.when(
              data: (muted) => _SoundMuteToggle(
                muted: muted,
                onChanged: (value) {
                  unawaited(
                    ref.read(soundServiceProvider).play(SoundEffect.uiTap),
                  );
                  ref.read(soundMutedProvider.notifier).set(value);
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PeekPanel(
          side: _PeekSide.left,
          asset: 'assets/ui/cat_sit_tuxedo.png',
          width: 50,
          bottom: -16,
          panel: _SettingsPanel(
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
        ),
        const SizedBox(height: AppSpacing.lg),
        _PeekPanel(
          side: _PeekSide.right,
          asset: 'assets/ui/cat_whiskers_black.png',
          width: 44,
          bottom: -16,
          panel: _SettingsPanel(
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
                _CreditRichLine(
                  parts: const [
                    (text: 'Music by ', url: null),
                    (
                      text: 'Krzysztof Szymanski',
                      url:
                          'https://pixabay.com/users/djartmusic-46653586/'
                          '?utm_source=link-attribution&utm_medium=referral'
                          '&utm_campaign=music&utm_content=301292',
                    ),
                    (text: ' from ', url: null),
                    (
                      text: 'Pixabay',
                      url:
                          'https://pixabay.com//?utm_source=link-attribution'
                          '&utm_medium=referral&utm_campaign=music'
                          '&utm_content=301292',
                    ),
                    (text: '.', url: null),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PeekPanel(
          side: _PeekSide.left,
          asset: 'assets/ui/cat_prayer_cream.png',
          width: 42,
          bottom: -16,
          panel: _SettingsPanel(
            title: 'Support this app',
            description:
                "Built solo by a developer who struggles with drinking water "
                "too. It's free to use — if it's helped you out, support is "
                "always appreciated.",
            // A Row, not a bare PixelButton, is what actually hugs the
            // button to its content width here — see the matching comment
            // on the Meowdrate! button in flood_home_screen.dart.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: PixelButton(
                    onPressed: () {
                      unawaited(
                        ref.read(soundServiceProvider).play(SoundEffect.uiTap),
                      );
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
                        Flexible(
                          child: Text(
                            'Support on Ko-fi',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PeekPanel(
          side: _PeekSide.right,
          asset: 'assets/ui/cat_boxnap_grey.png',
          width: 46,
          bottom: -16,
          panel: _SettingsPanel(
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
        ),
      ],
    );
  }
}

enum _PeekSide { left, right }

/// Wraps a settings panel with a small cute glyph peeking over its bottom
/// corner, alternating sides down the sheet — the same treatment the
/// Credits panel originated (see its git history), just spread across every
/// panel instead of confined to one spot.
class _PeekPanel extends StatelessWidget {
  const _PeekPanel({
    required this.panel,
    required this.side,
    required this.asset,
    required this.width,
    required this.bottom,
  });

  final Widget panel;
  final _PeekSide side;
  final String asset;
  final double width;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        panel,
        Positioned(
          left: side == _PeekSide.left ? 12 : null,
          right: side == _PeekSide.right ? 12 : null,
          bottom: bottom,
          child: Image.asset(
            asset,
            width: width,
            filterQuality: FilterQuality.none,
          ),
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
          _linkSpan(text: linkText, url: url, colors: colors, baseStyle: baseStyle),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

/// A tappable [WidgetSpan] with proper link semantics (announced and
/// targetable as a link by TalkBack/VoiceOver), for embedding inside a
/// [Text.rich] alongside plain [TextSpan]s. Replaces the earlier approach of
/// a [TextSpan] with a bare [TapGestureRecognizer], which is tappable but
/// invisible to assistive tech — a [TextSpan] can't carry [Semantics] on its
/// own, only a widget can.
WidgetSpan _linkSpan({
  required String text,
  required String url,
  required AppColors colors,
  required TextStyle baseStyle,
}) {
  return WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: Semantics(
      link: true,
      label: text,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Text(
            text,
            style: baseStyle.copyWith(
              color: colors.accent,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Like [_CreditLine], but for attribution text with more than one linked
/// segment (e.g. crediting both an artist and the site they're hosted on)
/// — each part is either plain text (`url: null`) or a tappable link.
class _CreditRichLine extends StatelessWidget {
  const _CreditRichLine({required this.parts});

  final List<({String text, String? url})> parts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseStyle = TextStyle(color: colors.textMuted, fontSize: 13);
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          for (final part in parts)
            part.url == null
                ? TextSpan(text: part.text)
                : _linkSpan(
                    text: part.text,
                    url: part.url!,
                    colors: colors,
                    baseStyle: baseStyle,
                  ),
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
    // Wrap (not Row) so at a large system text-scale setting, where the
    // three chips no longer fit on one line, the third one flows onto a
    // second line instead of overflowing off the edge of the panel.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _AppearanceChip(
          label: 'System',
          icon: Icons.brightness_auto,
          selected: mode == ThemeMode.system,
          onPressed: () => onChanged(ThemeMode.system),
        ),
        _AppearanceChip(
          label: 'Light',
          icon: Icons.light_mode,
          selected: mode == ThemeMode.light,
          onPressed: () => onChanged(ThemeMode.light),
        ),
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
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
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
          semanticLabel: 'Decrease daily glass goal',
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
          semanticLabel: 'Increase daily glass goal',
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
  const _StepperButton({
    required this.assetPath,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String assetPath;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    // The asset already is a small rounded-square button (background,
    // border and glyph baked in as one piece) — no Material/InkWell circle
    // needed on top of it, that was the "CSS-drawn" chrome that made the
    // bare-glyph version look unfinished. MouseRegion alone (no InkWell)
    // still gets it the pointer-on-hover cursor the other buttons have.
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: MouseRegion(
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
              excludeFromSemantics: true,
            ),
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
    // the same UI kit as everything else. Wrap (not Row), same reason as
    // the Appearance toggle: keeps a large system text-scale setting from
    // overflowing instead of flowing the second chip onto its own line.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
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

/// Same pill-chip pair as [_AppearanceToggle]/[_RemindersSection]'s toggle
/// — "muted" here is the persisted setting (everything off), so the chip
/// selection is inverted from it (On == not muted).
class _SoundMuteToggle extends StatelessWidget {
  const _SoundMuteToggle({required this.muted, required this.onChanged});

  final bool muted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // Wrap (not Row) — see _AppearanceToggle/_RemindersSection for why.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        PixelButton(
          height: 44,
          onPressed: () => onChanged(true),
          muted: !muted,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.volume_off_outlined, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text('Off'),
            ],
          ),
        ),
        PixelButton(
          height: 44,
          onPressed: () => onChanged(false),
          muted: muted,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.volume_up_outlined, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text('On'),
            ],
          ),
        ),
      ],
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
        Flexible(
          child: Text(
            streak == 0
                ? 'No days in a row yet'
                : '$streak day${streak == 1 ? '' : 's'} in a row',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.text,
              fontFamily: kHeadingFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
