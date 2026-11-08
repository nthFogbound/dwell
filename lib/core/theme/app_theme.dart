import 'package:flutter/material.dart';

/// Central place for Dwell's look: navy primary, bright yellow accent.
class AppTheme {
  AppTheme._(); // Static values only; no instances.

  static const Color _navy = Color(0xFF1B2A5C);
  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _ink = Color(0xFF14161C); // near-black, for text on yellow

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness brightness) {
    // fromSeed generates a full palette; we then pin the key roles.
    final base = ColorScheme.fromSeed(
      seedColor: _navy,
      brightness: brightness,
    );

    if (brightness == Brightness.light) {
      return base.copyWith(
        primary: _navy,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFDDE3FF),
        onPrimaryContainer: const Color(0xFF0B1640),
        tertiary: _yellow,
        onTertiary: _ink,
        tertiaryContainer: const Color(0xFFFFF1A6),
        onTertiaryContainer: const Color(0xFF3A3000),
        surface: const Color(0xFFF8F9FC),
      );
    }

    // Dark: navy is too dark to read as a foreground color, so primary
    // becomes a light navy tint and navy moves to the container role.
    return base.copyWith(
      primary: const Color(0xFFB4C0FF),
      onPrimary: const Color(0xFF0B1640),
      primaryContainer: _navy,
      onPrimaryContainer: const Color(0xFFDDE3FF),
      tertiary: _yellow,
      onTertiary: _ink,
      tertiaryContainer: const Color(0xFF4A3F00),
      onTertiaryContainer: const Color(0xFFFFF1A6),
      surface: const Color(0xFF0F1117),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = _scheme(brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.tertiary, // yellow pill behind selected item
        selectedIconTheme: IconThemeData(color: scheme.onTertiary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}