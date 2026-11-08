import 'package:flutter/material.dart';

/// Central place for Dwell's look. Change the seed color to re-theme everything.
class AppTheme {
  AppTheme._(); // Prevents creating instances; this class only holds static values.

  static const Color _seed = Color(0xFF3F51B5);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // fromSeed generates a full, consistent Material 3 palette from one color.
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
      ),
    );
  }
}
