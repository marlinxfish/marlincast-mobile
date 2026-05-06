import 'package:flutter/material.dart';

import '../features/browser/presentation/browser_page.dart';
import '../features/file_explorer/presentation/file_explorer_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../theme/marlin_theme.dart';
import '../theme/theme_controller.dart';
import 'app_constants.dart';
import 'app_routes.dart';

class MarlinCastApp extends StatefulWidget {
  const MarlinCastApp({
    super.key,
    this.palette = MarlinThemePalette.ocean,
    this.showBrowserWebView = true,
  });

  final MarlinThemePalette palette;
  final bool showBrowserWebView;

  @override
  State<MarlinCastApp> createState() => _MarlinCastAppState();
}

class _MarlinCastAppState extends State<MarlinCastApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController(initialPalette: widget.palette);
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          return MaterialApp(
            title: AppConstants.name,
            debugShowCheckedModeBanner: false,
            theme: MarlinThemes.byPalette(_themeController.palette),
            routes: {
              AppRoutes.home: (_) => const HomePage(),
              AppRoutes.browser: (_) => BrowserPage(
                showWebView: widget.showBrowserWebView,
              ),
              AppRoutes.fileExplorer: (_) => const FileExplorerPage(),
              AppRoutes.settings: (_) => const SettingsPage(),
            },
          );
        },
      ),
    );
  }
}
