import 'package:flutter/material.dart';

import '../features/browser/presentation/browser_page.dart';
import '../features/file_explorer/presentation/file_explorer_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../theme/marlin_theme.dart';
import 'app_constants.dart';
import 'app_routes.dart';

class MarlinCastApp extends StatelessWidget {
  const MarlinCastApp({
    super.key,
    this.palette = MarlinThemePalette.ocean,
    this.showBrowserWebView = true,
  });

  final MarlinThemePalette palette;
  final bool showBrowserWebView;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.name,
      debugShowCheckedModeBanner: false,
      theme: MarlinThemes.byPalette(palette),
      routes: {
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.browser: (_) => BrowserPage(showWebView: showBrowserWebView),
        AppRoutes.fileExplorer: (_) => const FileExplorerPage(),
        AppRoutes.settings: (_) => const SettingsPage(),
      },
    );
  }
}
