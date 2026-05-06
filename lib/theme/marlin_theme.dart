import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum MarlinThemePalette {
  ocean,
  ember,
  mint,
  midnight,
}

extension MarlinThemePaletteLabel on MarlinThemePalette {
  String get label {
    return switch (this) {
      MarlinThemePalette.ocean => 'Ocean',
      MarlinThemePalette.ember => 'Ember',
      MarlinThemePalette.mint => 'Mint',
      MarlinThemePalette.midnight => 'Midnight',
    };
  }

  String get description {
    return switch (this) {
      MarlinThemePalette.ocean => 'Biru terang untuk tampilan default.',
      MarlinThemePalette.ember => 'Oranye hangat dan kontras.',
      MarlinThemePalette.mint => 'Hijau segar dan ringan.',
      MarlinThemePalette.midnight => 'Mode gelap untuk malam.',
    };
  }
}

class MarlinThemes {
  static final ThemeData oceanLight = _theme(
    seedColor: const Color(0xFF0EA5E9),
    scaffoldBackground: const Color(0xFFF4FAFF),
  );

  static final ThemeData emberLight = _theme(
    seedColor: const Color(0xFFF97316),
    scaffoldBackground: const Color(0xFFFFF7ED),
  );

  static final ThemeData mintLight = _theme(
    seedColor: const Color(0xFF10B981),
    scaffoldBackground: const Color(0xFFF0FDF4),
  );

  static final ThemeData midnightDark = _theme(
    seedColor: const Color(0xFF38BDF8),
    scaffoldBackground: const Color(0xFF050B18),
    brightness: Brightness.dark,
  );

  static ThemeData byPalette(MarlinThemePalette palette) {
    return switch (palette) {
      MarlinThemePalette.ocean => oceanLight,
      MarlinThemePalette.ember => emberLight,
      MarlinThemePalette.mint => mintLight,
      MarlinThemePalette.midnight => midnightDark,
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
