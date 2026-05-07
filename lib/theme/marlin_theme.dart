import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum MarlinThemeMode {
  light,
  dark,
}

extension MarlinThemeModeLabel on MarlinThemeMode {
  String get label {
    return switch (this) {
      MarlinThemeMode.light => 'Light',
      MarlinThemeMode.dark => 'Dark',
    };
  }

  String get description {
    return switch (this) {
      MarlinThemeMode.light => 'Tema ocean terang untuk siang hari.',
      MarlinThemeMode.dark => 'Tema gelap untuk malam hari.',
    };
  }
}

class MarlinThemes {
  static final ThemeData light = _theme(
    seedColor: const Color(0xFF0EA5E9),
    scaffoldBackground: const Color(0xFFF4FAFF),
  );

  static final ThemeData dark = _theme(
    seedColor: const Color(0xFF38BDF8),
    scaffoldBackground: const Color(0xFF050B18),
    brightness: Brightness.dark,
  );

  static ThemeData byMode(MarlinThemeMode mode) {
    return switch (mode) {
      MarlinThemeMode.light => light,
      MarlinThemeMode.dark => dark,
    };
  }

  static ThemeData _theme({
    required Color seedColor,
    required Color scaffoldBackground,
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final baseTheme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
