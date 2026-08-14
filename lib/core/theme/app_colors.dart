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
    required this.gold,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color textMuted;
  final Color primary;
  final Color primaryPressed;
  final Color border;
  final Color success;
  final Color gold;

  /// Ocean-toned palette carried over from the original prototype.
  static const dark = AppColors(
    background: Color(0xFF0B1220),
    surface: Color(0xFF101A2E),
    text: Color(0xFFF5F7FF),
    textMuted: Color(0xFFB8C0D9),
    primary: Color(0xFF6EE7FF),
    primaryPressed: Color(0xFF35D6F8),
    border: Color(0x1FF5F7FF),
    success: Color(0xFF6EE7FF),
    gold: Color(0xFFFFD166),
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
    gold: Color(0xFFC98A12),
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
    Color? gold,
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
      gold: gold ?? this.gold,
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
      gold: Color.lerp(gold, other.gold, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
