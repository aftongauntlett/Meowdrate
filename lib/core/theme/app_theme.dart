import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _themeFor(AppColors.dark, Brightness.dark);

  static ThemeData get light => _themeFor(AppColors.light, Brightness.light);

  static ThemeData _themeFor(AppColors colors, Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              surface: colors.background,
              primary: colors.primary,
              onPrimary: colors.background,
              secondary: colors.accent,
              onSurface: colors.text,
            )
          : ColorScheme.light(
              surface: colors.background,
              primary: colors.primary,
              onPrimary: colors.background,
              secondary: colors.accent,
              onSurface: colors.text,
            ),
      fontFamily: 'Inter',
      extensions: [colors],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.background,
          disabledBackgroundColor: colors.surface,
          disabledForegroundColor: colors.textMuted,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          elevation: 0,
          // A chunky, slightly hand-drawn shape instead of a squared-off
          // website button — uneven corner radii and a thick contrast
          // outline read as "game UI" rather than "form submit".
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(20),
            ),
            side: BorderSide(color: colors.background.withValues(alpha: 0.85), width: 2.5),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.textMuted,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
