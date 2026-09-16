import 'package:flutter/material.dart';

/// Accent colours the user can pick from in Profile → Appearance.
enum AppAccent {
  emerald('Emerald', Color(0xFF12B76A), Color(0xFF32D583)),
  violet('Violet', Color(0xFF7A5AF8), Color(0xFF9B8AFB)),
  ocean('Ocean', Color(0xFF0BA5EC), Color(0xFF36BFFA)),
  sunset('Sunset', Color(0xFFEF6820), Color(0xFFF38744)),
  rose('Rose', Color(0xFFE31B54), Color(0xFFFD6F8E));

  const AppAccent(this.label, this.light, this.dark);

  final String label;

  /// Seed used when the app renders in light mode.
  final Color light;

  /// Brighter seed for dark mode, so the accent keeps its punch on dark
  /// surfaces without glowing.
  final Color dark;

  Color seedFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static AppAccent fromName(String? name) {
    return AppAccent.values.firstWhere(
      (a) => a.name == name,
      orElse: () => AppAccent.emerald,
    );
  }
}

/// Neutral ladder + semantic colours shared by both themes.
///
/// Material's generated neutrals are usable but muddy, so the surface ramp is
/// defined by hand and layered over `ColorScheme.fromSeed` in [AppTheme].
abstract final class AppColors {
  // Light neutrals
  static const lightBackground = Color(0xFFF6F7F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF0F2F5);
  static const lightOutline = Color(0xFFE3E7EC);
  static const lightTextPrimary = Color(0xFF0F1722);
  static const lightTextSecondary = Color(0xFF5A6572);

  // Dark neutrals
  static const darkBackground = Color(0xFF0A0E14);
  static const darkSurface = Color(0xFF141A22);
  static const darkSurfaceAlt = Color(0xFF1C242E);
  static const darkOutline = Color(0xFF2A333F);
  static const darkTextPrimary = Color(0xFFF3F5F7);
  static const darkTextSecondary = Color(0xFF98A2B3);

  // Semantics — form feedback reads the same in both themes.
  static const success = Color(0xFF17B26A);
  static const warning = Color(0xFFF79009);
  static const danger = Color(0xFFF04438);

  /// Colour for a 0..1 form score: red → amber → green.
  static Color forScore(double score) {
    if (score >= 0.8) return success;
    if (score >= 0.55) return warning;
    return danger;
  }
}
