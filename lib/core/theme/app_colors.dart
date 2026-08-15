import 'package:flutter/material.dart';

/// Named color tokens for the app's light and dark palettes, exposed as a
/// ThemeExtension so widgets read them via `context.colors` and pick up
/// changes automatically when the user's Light/Dark/System preference
/// changes — completely independent of the flood scene's own automatic
/// day/night sky, which is a separate concern (see FloodScene).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.primaryPressed,
    required this.border,
    required this.success,
    required this.accent,
    required this.cardBackground,
    required this.cardBorder,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color textMuted;
  final Color primary;
  final Color primaryPressed;
  final Color border;
  final Color success;

  /// Secondary accent — used for things like the selected segment on the
  /// appearance toggle. Teal, to sit alongside the primary cyan rather than
  /// clash with it (an earlier gold/yellow read as off-theme).
  final Color accent;

  /// Card treatment for surfaces that draw their own background/border in
  /// code instead of leaning on the (light-only) pastel `panel_card.png`
  /// art — Settings' panels in dark mode, and the Drink Moment timer box in
  /// both modes, so the two screens read as one system. Light mode keeps
  /// the original surface/border pairing (the pastel art already looks
  /// right against it); dark mode gets a near-black purple fill with a
  /// periwinkle border pulled from the same blue as the pixel-art buttons,
  /// instead of a washed-out gray.
  final Color cardBackground;
  final Color cardBorder;

  /// Ocean-toned palette carried over from the original prototype. Dark
  /// mode deliberately keeps background and surface far apart: background
  /// goes properly deep/near-black, while surface (nav bar, Settings'
  /// panels) stays a lighter, more legible navy so light-colored icons and
  /// UI-kit sprites read clearly against it instead of nearly vanishing.
  static const dark = AppColors(
    background: Color(0xFF05070C),
    surface: Color(0xFF182540),
    text: Color(0xFFF5F7FF),
    textMuted: Color(0xFFB8C0D9),
    primary: Color(0xFF6EE7FF),
    primaryPressed: Color(0xFF35D6F8),
    border: Color(0x1FF5F7FF),
    success: Color(0xFF6EE7FF),
    accent: Color(0xFF2DD4BF),
    // Near-black with a deliberate violet cast, not a flat/gray black —
    // that's what made the tinted-pastel-art version of this read as
    // "gray" rather than "dark purple."
    cardBackground: Color(0xFF130B24),
    // Same periwinkle as the pixel-art buttons (assets/ui/btn_pill_blue.png,
    // icon_button_plus/minus.png) — one blue running through the whole app
    // instead of an unrelated accent.
    cardBorder: Color(0xFF8CAAEE),
  );

  static const light = AppColors(
    background: Color(0xFFF5F7FC),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF12172B),
    textMuted: Color(0xFF5C6478),
    primary: Color(0xFF1897B3),
    primaryPressed: Color(0xFF12768C),
    border: Color(0x1F12172B),
    success: Color(0xFF1897B3),
    accent: Color(0xFF0D9488),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0x1F12172B),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? textMuted,
    Color? primary,
    Color? primaryPressed,
    Color? border,
    Color? success,
    Color? accent,
    Color? cardBackground,
    Color? cardBorder,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      border: border ?? this.border,
      success: success ?? this.success,
      accent: accent ?? this.accent,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
