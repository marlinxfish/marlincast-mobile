import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/presentation/widgets/menu_button.dart';
import '../../home/presentation/widgets/home_drawer.dart';
import '../application/browser_controller.dart';
import '../application/browser_url_resolver.dart';
import '../application/cosmetic_filter_script.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({
    super.key,
    this.showWebView = true,
  });

  final bool showWebView;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  final _browserController = BrowserController();
  final _urlController = TextEditingController(text: 'https://google.com');

  InAppWebViewController? _webViewController;

  @override
  void dispose() {
    _browserController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.showWebView,
      onPopInvokedWithResult: _handleSystemBack,
      child: Scaffold(
        drawer: const HomeDrawer(),
        body: AnimatedBuilder(
          animation: _browserController,
          builder: (context, child) {
            return SafeArea(
              child: Column(
                children: [
                  _BrowserToolbar(
                    controller: _urlController,
                    blockedAds: _browserController.blockedAds,
                    onSubmitted: _loadUrl,
                  ),
                  if (_browserController.progress < 1)
                    LinearProgressIndicator(value: _browserController.progress),
                  Expanded(
                    child: Stack(
                      children: [
                        child ?? const _BrowserUnavailableView(),
                        if (_browserController.hasDetectedVideo)
                          _DetectedVideoSheet(
                            url: _browserController.detectedVideo!.url,
                            onClose: _browserController.clearDetectedVideo,
                            onCast: () {},
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          child: widget.showWebView ? _buildWebView() : null,
        ),
      ),
    );
  }

  Future<void> _handleSystemBack(bool didPop, Object? result) async {
    if (didPop || !widget.showWebView) {
      return;
    }

    final controller = _webViewController;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  Widget _buildWebView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_urlController.text)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        transparentBackground: false,
        useShouldInterceptRequest: true,
        preferredContentMode: UserPreferredContentMode.MOBILE,
        algorithmicDarkeningAllowed: isDarkMode,
        forceDark: isDarkMode ? ForceDark.AUTO : ForceDark.OFF,
        forceDarkStrategy: ForceDarkStrategy.PREFER_WEB_THEME_OVER_USER_AGENT_DARKENING,
      ),
      initialUserScripts: UnmodifiableListView([
        UserScript(
          source: CosmeticFilterScript.source,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
        ),
      ]),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStop: (controller, url) async {
        if (url != null) {
          _browserController.setCurrentUrl(Uri.parse(url.toString()));
          _urlController.text = url.toString();
        }
        await controller.evaluateJavascript(source: CosmeticFilterScript.source);
      },
      onProgressChanged: (controller, progress) {
        _browserController.setProgress(progress / 100);
      },
      shouldInterceptRequest: (controller, request) async {
        final uri = Uri.parse(request.url.toString());
        final detected = _browserController.inspectVideo(url: uri);
        final shouldBlock = await _browserController.shouldBlock(
          url: uri,
          sourceUrl: _browserController.currentUrl,
          requestType: _requestType(request),
        );

        if (detected != null || shouldBlock) {
          return WebResourceResponse(
            data: Uint8List(0),
            statusCode: 204,
            reasonPhrase: detected != null ? 'Video captured' : 'Blocked',
          );
        }

        return null;
      },
    );
  }

  String _requestType(WebResourceRequest request) {
    final path = request.url.path.toLowerCase();
    if (path.endsWith('.js')) {
      return 'script';
    }
    if (path.endsWith('.css')) {
      return 'stylesheet';
    }
    if (path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.webp')) {
      return 'image';
    }
    if (path.endsWith('.mp4') ||
        path.endsWith('.m3u8') ||
        path.endsWith('.ts')) {
      return 'media';
    }
    return 'other';
  }

  void _loadUrl(String value) {
    final uri = BrowserUrlResolver.resolve(value);
    _urlController.text = uri.toString();
    _browserController.setCurrentUrl(uri);
    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }
}

class _BrowserUnavailableView extends StatelessWidget {
  const _BrowserUnavailableView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Browser engine tidak aktif di test.'));
  }
}

class _BrowserToolbar extends StatelessWidget {
  const _BrowserToolbar({
    required this.controller,
    required this.blockedAds,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final int blockedAds;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Row(
        children: [
          const MenuButton(),
          const SizedBox(width: 8),
          Expanded(
            child: _UrlTextField(
              controller: controller,
              colorScheme: colorScheme,
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Iklan diblokir',
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.shieldCheck, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    '$blockedAds',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlTextField extends StatefulWidget {
  const _UrlTextField({
    required this.controller,
    required this.colorScheme,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ColorScheme colorScheme;
  final ValueChanged<String> onSubmitted;

  @override
  State<_UrlTextField> createState() => _UrlTextFieldState();
}

class _UrlTextFieldState extends State<_UrlTextField> {
  bool _shouldSelectAllOnTap = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: widget.controller,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        style: Theme.of(context).textTheme.bodyMedium,
        onSubmitted: widget.onSubmitted,
        onTap: _handleTap,
        onTapOutside: (_) => _shouldSelectAllOnTap = true,
        decoration: InputDecoration(
          hintText: 'Masukkan URL',
          prefixIcon: const Icon(LucideIcons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: widget.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (!_shouldSelectAllOnTap || widget.controller.text.isEmpty) {
      return;
    }

    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.controller.text.length,
    );
    _shouldSelectAllOnTap = false;
  }
}

class _DetectedVideoSheet extends StatelessWidget {
  const _DetectedVideoSheet({
    required this.url,
    required this.onClose,
    required this.onCast,
  });

  final Uri url;
  final VoidCallback onClose;
  final VoidCallback onCast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        color: colorScheme.surface,
        elevation: 18,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(LucideIcons.video, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '1 Video Ditemukan',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      url.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: onClose,
                icon: const Icon(LucideIcons.x),
              ),
              FilledButton(
                onPressed: onCast,
                child: const Text('Cast'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
