import 'package:flutter/material.dart';

/// Custom font families for the app.
///
/// Add `.ttf` / `.otf` files under [assetsDir], register them in `pubspec.yaml`,
/// then set [useCustomFonts] to `true`.
abstract final class AppFonts {
  static const String assetsDir = 'assets/fonts';

  /// Primary UI font — matches `family: CircularStd` in pubspec.yaml.
  static const String primary = 'CircularStd';

  static const bool useCustomFonts = true;

  static String? get primaryFamily => useCustomFonts ? primary : null;

  static TextTheme apply(TextTheme base) {
    final family = primaryFamily;
    if (family == null) return base;

    return base.apply(
      fontFamily: family,
      displayColor: null,
      bodyColor: null,
    );
  }
}
