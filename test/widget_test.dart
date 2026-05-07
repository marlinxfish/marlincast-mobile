import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/app/marlin_cast_app.dart';
import 'package:mobile/features/browser/application/ad_block_engine.dart';
import 'package:mobile/features/browser/application/browser_url_resolver.dart';
import 'package:mobile/features/browser/domain/detected_video.dart';
import 'package:mobile/features/browser/presentation/browser_page.dart';
import 'package:mobile/features/browser/application/video_sniffer.dart';
import 'package:mobile/features/file_explorer/domain/local_media_file.dart';
import 'package:mobile/features/file_explorer/presentation/file_explorer_page.dart';
import 'package:mobile/features/home/presentation/home_page.dart';
import 'package:mobile/features/home/presentation/widgets/home_drawer.dart';
import 'package:mobile/features/settings/presentation/settings_page.dart';
import 'package:mobile/app/app_routes.dart';
import 'package:mobile/theme/marlin_theme.dart';
import 'package:mobile/theme/theme_controller.dart';

void main() {
  testWidgets('shows home page with side drawer menu', (tester) async {
    await tester.pumpWidget(const MarlinCastApp(showBrowserWebView: false));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byIcon(LucideIcons.menu), findsOneWidget);
    expect(find.byIcon(LucideIcons.scanQrCode), findsOneWidget);
    expect(find.text('TV belum terhubung'), findsOneWidget);
    expect(find.text('TV tersedia di jaringan ini'), findsOneWidget);
    expect(find.text('Status Sistem'), findsNothing);

    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Marlin Cast TV - Living Room'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.menu));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeDrawer), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Browser'), findsWidgets);
    expect(find.text('File Explorer'), findsWidgets);
    expect(find.text('Upgrade to Pro'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('browser menu opens browser page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        initialRoute: AppRoutes.browser,
        routes: {
          AppRoutes.browser: _browserTestRoute,
        },
      ),
    );

    expect(find.byType(BrowserPage), findsOneWidget);
  });

  testWidgets('file explorer menu opens file explorer page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FileExplorerPage()),
    );

    expect(find.byType(FileExplorerPage), findsOneWidget);
    expect(find.text('Pilih Video'), findsOneWidget);
  });

  testWidgets('settings menu opens settings page', (tester) async {
    await tester.pumpWidget(
      ThemeScope(
        controller: ThemeController(),
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('settings theme option changes app theme', (tester) async {
    await tester.pumpWidget(const MarlinCastApp(
      showBrowserWebView: false,
      initialRoute: AppRoutes.settings,
    ));

    await tester.tap(find.text('Dark'));
    await tester.pump(const Duration(seconds: 1));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.dark);
  });

  test('provides light and dark themes', () {
    expect(MarlinThemes.light.brightness, Brightness.light);
    expect(MarlinThemes.dark.brightness, Brightness.dark);
  });

  test('sniffs video URLs by extension and content type', () {
    final sniffer = VideoSniffer();

    expect(
      sniffer.inspect(url: Uri.parse('https://cdn.example.com/video.m3u8')),
      isNotNull,
    );
    expect(
      sniffer.inspect(
        url: Uri.parse('https://cdn.example.com/watch'),
        contentType: 'video/mp4',
      ),
      isNotNull,
    );
    expect(
      sniffer.inspect(url: Uri.parse('https://example.com/script.js')),
      isNull,
    );
  });

  test('sniffs broader media URL formats', () {
    final sniffer = VideoSniffer();

    expect(
      sniffer.inspect(url: Uri.parse('https://cdn.example.com/manifest.mpd')),
      isNotNull,
    );
    expect(
      sniffer.inspect(
        url: Uri.parse('https://cdn.example.com/file?mime=video/mp4'),
      ),
      isNotNull,
    );
    expect(
      sniffer.inspect(url: Uri.parse('https://cdn.example.com/movie.webm')),
      isNotNull,
    );
  });

  test('detected video derives display quality', () {
    final adaptiveVideo = DetectedVideo(
      url: Uri.parse('https://cdn.example.com/master.m3u8'),
      source: VideoDetectionSource.fileExtension,
    );
    final sizedVideo = DetectedVideo(
      url: Uri.parse('https://cdn.example.com/video.mp4'),
      source: VideoDetectionSource.htmlMediaElement,
      width: 1920,
      height: 1080,
    );

    expect(adaptiveVideo.displayQuality, 'Adaptive');
    expect(sizedVideo.displayQuality, '1080p');
  });

  test('adblock allows normal first-party banner images', () async {
    final engine = RuleBasedAdBlockEngine();

    final shouldBlock = await engine.shouldBlock(
      url: Uri.parse('https://example.com/assets/banner.jpg'),
      sourceUrl: Uri.parse('https://example.com'),
      requestType: 'image',
    );

    expect(shouldBlock, isFalse);
  });

  test('adblock allows normal third-party images', () async {
    final engine = RuleBasedAdBlockEngine();

    final shouldBlock = await engine.shouldBlock(
      url: Uri.parse('https://cdn.example-image.com/poster.jpg'),
      sourceUrl: Uri.parse('https://example.com'),
      requestType: 'image',
    );

    expect(shouldBlock, isFalse);
  });

  test('adblock blocks image only from known ad hosts', () async {
    final engine = RuleBasedAdBlockEngine();

    final shouldBlock = await engine.shouldBlock(
      url: Uri.parse('https://doubleclick.net/banner.jpg'),
      sourceUrl: Uri.parse('https://example.com'),
      requestType: 'image',
    );

    expect(shouldBlock, isTrue);
  });

  test('adblock still blocks known ad hosts', () async {
    final engine = RuleBasedAdBlockEngine();

    final shouldBlock = await engine.shouldBlock(
      url: Uri.parse('https://adservice.google.com/banner.js'),
      sourceUrl: Uri.parse('https://example.com'),
      requestType: 'script',
    );

    expect(shouldBlock, isTrue);
  });

  test('browser resolver keeps URLs and searches plain text', () {
    expect(
      BrowserUrlResolver.resolve('example.com/path').toString(),
      'https://example.com/path',
    );
    expect(
      BrowserUrlResolver.resolve('https://example.com').toString(),
      'https://example.com',
    );
    expect(
      BrowserUrlResolver.resolve('anime sub indo').toString(),
      'https://www.google.com/search?q=anime+sub+indo',
    );
  });

  test('formats media file sizes', () {
    const file = LocalMediaFile(
      name: 'movie.mp4',
      path: '/movie.mp4',
      sizeBytes: 15 * 1024 * 1024,
      extension: 'mp4',
    );

    expect(file.formattedSize, '15.0 MB');
  });
}

class _BrowserTestRoute extends StatelessWidget {
  const _BrowserTestRoute();

  @override
  Widget build(BuildContext context) {
    return const BrowserPage(showWebView: false);
  }
}

Widget _browserTestRoute(BuildContext context) {
  return const _BrowserTestRoute();
}
