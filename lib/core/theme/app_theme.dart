import 'package:flutter/material.dart';

import 'app_fonts.dart';

class AppTheme {
  const AppTheme._();

  /// Maroon brand (#800000).
  static const Color brandMaroon = Color(0xFF800000);

  /// App shell background — very light sky blue tint.
  static const Color primary = Color(0xFFF3FBFE);

  static const Color secondary = Color(0xFF6D2D2D);
  static const Color third = Color(0xFFF9F3F1);
  static const Color accent = Color(0xFFE53935);
  static const Color surfaceGrey = Color(0xFFF5F5F5);

  /// Product cards, cart rows, and listing tiles stay pure white.
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF272727);
  static const Color textMuted = Color(0x7F272727);
  static const Color brandActive = brandMaroon;
  static const Color favouriteActive = brandMaroon;
  static const Color navInactive = Color(0xFF9E9E9E);
  static const Color textDark = Colors.black;
  static const Color textLight = Colors.white;

  static ThemeData get lightTheme {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: secondary,
      onPrimary: textLight,
      secondary: secondary,
      onSecondary: textLight,
      error: Colors.red,
      onError: textLight,
      surface: primary,
      onSurface: textDark,
    );

    final textTheme = AppFonts.apply(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.primaryFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: primary,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: primary,
        indicatorColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? const Color(0xFF800000) : textDark.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? const Color(0xFF800000) : textDark.withValues(alpha: 0.55),
            size: 24,
          );
        }),
      ),
      cardColor: primary,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: third,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 1.4),
        ),
      ),
    );
  }
}
