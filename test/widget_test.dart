import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/app/marlin_cast_app.dart';
import 'package:mobile/features/browser/application/ad_block_engine.dart';
import 'package:mobile/features/browser/application/browser_url_resolver.dart';
import 'package:mobile/features/browser/presentation/browser_page.dart';
import 'package:mobile/features/browser/application/video_sniffer.dart';
import 'package:mobile/features/file_explorer/domain/local_media_file.dart';
import 'package:mobile/features/file_explorer/presentation/file_explorer_page.dart';
import 'package:mobile/features/home/presentation/home_page.dart';
import 'package:mobile/features/home/presentation/widgets/home_drawer.dart';
import 'package:mobile/features/settings/presentation/settings_page.dart';
import 'package:mobile/theme/marlin_theme.dart';

void main() {
  testWidgets('shows home page with side drawer menu', (tester) async {
    await tester.pumpWidget(const MarlinCastApp(showBrowserWebView: false));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byIcon(LucideIcons.menu), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(HomeDrawer), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Browser'), findsWidgets);
    expect(find.text('File Explorer'), findsWidgets);
    expect(find.text('Upgrade to Pro'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('browser menu opens browser page', (tester) async {
    await tester.pumpWidget(const MarlinCastApp(showBrowserWebView: false));

    await tester.tap(find.byIcon(LucideIcons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browser').last);
    await tester.pumpAndSettle();

    expect(find.byType(BrowserPage), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.menu));
    await tester.pumpAndSettle();

    final browserTile = tester.widget<Material>(
      find.ancestor(
        of: find.text('Browser').last,
        matching: find.byType(Material),
      ).first,
    );

    expect(browserTile.color, isNot(Colors.transparent));
  });

  testWidgets('file explorer menu opens file explorer page', (tester) async {
    await tester.pumpWidget(const MarlinCastApp(showBrowserWebView: false));

    await tester.tap(find.byIcon(LucideIcons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('File Explorer').last);
    await tester.pumpAndSettle();

    expect(find.byType(FileExplorerPage), findsOneWidget);
    expect(find.text('Pilih Video'), findsOneWidget);
  });

  testWidgets('settings menu opens settings page', (tester) async {
    await tester.pumpWidget(const MarlinCastApp(showBrowserWebView: false));

    await tester.tap(find.byIcon(LucideIcons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('settings theme option changes app theme', (tester) async {
    await tester.pumpWidget(const MarlinCastApp(showBrowserWebView: false));

    await tester.tap(find.byIcon(LucideIcons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

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
