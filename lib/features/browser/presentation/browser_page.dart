import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/presentation/widgets/menu_button.dart';
import '../../home/presentation/widgets/home_drawer.dart';
import '../application/browser_controller.dart';
import '../application/browser_preferences.dart';
import '../application/browser_url_resolver.dart';
import '../application/cosmetic_filter_script.dart';
import '../application/media_sniffer_script.dart';
import '../domain/detected_video.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key, this.showWebView = true});

  final bool showWebView;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  final _browserController = BrowserController();
  final _browserPreferences = BrowserPreferences();
  final _urlController = TextEditingController(text: 'https://google.com');
  final _urlFocusNode = FocusNode();
  bool? _browserDarkModeEnabled;

  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadBrowserPreferences();
  }

  @override
  void dispose() {
    _browserController.dispose();
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browserDarkModeEnabled =
        _browserDarkModeEnabled ??
        Theme.of(context).brightness == Brightness.dark;

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
                    focusNode: _urlFocusNode,
                    blockedAds: _browserController.blockedAds,
                    detectedVideoCount:
                        _browserController.detectedVideos.length,
                    darkModeEnabled: browserDarkModeEnabled,
                    onSubmitted: _loadUrl,
                    onDarkModeChanged: _setBrowserDarkMode,
                    onOpenDetectedVideos: _openDetectedVideos,
                  ),
                  if (_browserController.progress < 1)
                    LinearProgressIndicator(value: _browserController.progress),
                  Expanded(
                    child: Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (_) => _urlFocusNode.unfocus(),
                          child: child ?? const _BrowserUnavailableView(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          child: widget.showWebView
              ? _buildWebView(browserDarkModeEnabled)
              : null,
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

  Widget _buildWebView(bool browserDarkModeEnabled) {
    final forceDark = browserDarkModeEnabled ? ForceDark.AUTO : ForceDark.OFF;

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_urlController.text)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: true,
        mediaPlaybackRequiresUserGesture: false,
        transparentBackground: false,
        useShouldInterceptRequest: true,
        useShouldOverrideUrlLoading: true,
        supportMultipleWindows: true,
        preferredContentMode: UserPreferredContentMode.MOBILE,
        algorithmicDarkeningAllowed: browserDarkModeEnabled,
        forceDark: forceDark,
      ),
      initialUserScripts: UnmodifiableListView([
        UserScript(
          source: MediaSnifferScript.source,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
        UserScript(
          source: CosmeticFilterScript.source,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
        ),
      ]),
      onWebViewCreated: (controller) {
        _webViewController = controller;
        controller.addJavaScriptHandler(
          handlerName: 'marlinMediaDetected',
          callback: _handleJavaScriptMediaDetected,
        );
      },
      onLoadStop: (controller, url) async {
        if (url != null) {
          _browserController.setCurrentUrl(Uri.parse(url.toString()));
          _urlController.text = url.toString();
        }
        await controller.evaluateJavascript(
          source: CosmeticFilterScript.source,
        );
        await controller.evaluateJavascript(source: MediaSnifferScript.source);
      },
      onProgressChanged: (controller, progress) {
        _browserController.setProgress(progress / 100);
      },
      onScrollChanged: (controller, x, y) {
        _urlFocusNode.unfocus();
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url;
        if (url == null) {
          return NavigationActionPolicy.ALLOW;
        }

        if (_isSuspiciousRedirect(navigationAction)) {
          final allow = await _confirmPopupOrRedirect(
            title: 'Web ini ingin redirect',
            message: url.toString(),
          );
          return allow
              ? NavigationActionPolicy.ALLOW
              : NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },
      onCreateWindow: (controller, createWindowAction) async {
        final url = createWindowAction.request.url;
        final allow = await _confirmPopupOrRedirect(
          title: 'Web ini ingin membuka pop-up',
          message: url?.toString() ?? 'Pop-up tanpa URL jelas.',
        );

        if (allow && url != null) {
          await controller.loadUrl(urlRequest: URLRequest(url: url));
        }

        return true;
      },
      shouldInterceptRequest: (controller, request) async {
        final uri = Uri.parse(request.url.toString());
        final detected = _browserController.inspectVideo(
          url: uri,
          pageUrl: _browserController.currentUrl,
        );
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

  void _handleJavaScriptMediaDetected(List<dynamic> arguments) {
    if (arguments.isEmpty || arguments.first is! Map) {
      return;
    }

    final data = Map<String, dynamic>.from(arguments.first as Map);
    final urlValue = data['url']?.toString();
    if (urlValue == null || urlValue.isEmpty) {
      return;
    }

    final sourceValue = data['source']?.toString();
    final pageUrlValue = data['pageUrl']?.toString();
    final width = int.tryParse(data['width']?.toString() ?? '');
    final height = int.tryParse(data['height']?.toString() ?? '');
    final qualityLabel = data['qualityLabel']?.toString();
    final url = Uri.tryParse(urlValue);
    if (url == null) {
      return;
    }

    _browserController.addDetectedVideo(
      url: url,
      pageUrl:
          Uri.tryParse(pageUrlValue ?? '') ?? _browserController.currentUrl,
      source: sourceValue == 'javascriptFetch'
          ? VideoDetectionSource.javascriptFetch
          : VideoDetectionSource.htmlMediaElement,
      width: width,
      height: height,
      qualityLabel: qualityLabel,
    );
  }

  bool _isSuspiciousRedirect(NavigationAction action) {
    if (action.isForMainFrame != true || action.hasGesture == true) {
      return false;
    }

    final targetUrl = action.request.url;
    if (targetUrl == null) {
      return false;
    }

    final currentHost = _browserController.currentUrl.host;
    final targetHost = Uri.parse(targetUrl.toString()).host;
    if (_isGoogleBootstrapRedirect(
      currentHost: currentHost,
      targetHost: targetHost,
    )) {
      return false;
    }

    return currentHost.isNotEmpty &&
        targetHost.isNotEmpty &&
        currentHost != targetHost;
  }

  bool _isGoogleBootstrapRedirect({
    required String currentHost,
    required String targetHost,
  }) {
    const allowedGoogleHosts = {'google.com', 'www.google.com'};
    return allowedGoogleHosts.contains(currentHost) &&
        allowedGoogleHosts.contains(targetHost);
  }

  Future<bool> _confirmPopupOrRedirect({
    required String title,
    required String message,
  }) async {
    if (!mounted) {
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message, maxLines: 4, overflow: TextOverflow.ellipsis),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stop'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Biarkan'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _loadUrl(String value) {
    _urlFocusNode.unfocus();
    final uri = BrowserUrlResolver.resolve(value);
    _urlController.text = uri.toString();
    _browserController.setCurrentUrl(uri);
    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }

  Future<void> _setBrowserDarkMode(bool enabled) async {
    if (_browserDarkModeEnabled == enabled) {
      return;
    }

    setState(() => _browserDarkModeEnabled = enabled);
    await _browserPreferences.saveDarkModeEnabled(enabled);
    await _webViewController?.setSettings(
      settings: InAppWebViewSettings(
        forceDark: enabled ? ForceDark.AUTO : ForceDark.OFF,
        algorithmicDarkeningAllowed: enabled,
      ),
    );
    await _webViewController?.reload();
  }

  Future<void> _loadBrowserPreferences() async {
    final darkModeEnabled = await _browserPreferences.loadDarkModeEnabled();
    if (!mounted || darkModeEnabled == null) {
      return;
    }
    setState(() => _browserDarkModeEnabled = darkModeEnabled);
  }

  void _openDetectedVideos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DetectedVideosPage(videos: _browserController.detectedVideos),
      ),
    );
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
    required this.focusNode,
    required this.blockedAds,
    required this.detectedVideoCount,
    required this.darkModeEnabled,
    required this.onSubmitted,
    required this.onDarkModeChanged,
    required this.onOpenDetectedVideos,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int blockedAds;
  final int detectedVideoCount;
  final bool darkModeEnabled;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onOpenDetectedVideos;

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
              focusNode: focusNode,
              colorScheme: colorScheme,
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<bool>(
            tooltip: 'Menu browser',
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: onDarkModeChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: !darkModeEnabled,
                child: Row(
                  children: [
                    Icon(
                      darkModeEnabled ? LucideIcons.moon : LucideIcons.sun,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      darkModeEnabled
                          ? 'Matikan tema gelap'
                          : 'Aktifkan tema gelap',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          _DetectedVideoButton(
            count: detectedVideoCount,
            onTap: onOpenDetectedVideos,
          ),
        ],
      ),
    );
  }
}

class _DetectedVideoButton extends StatefulWidget {
  const _DetectedVideoButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  State<_DetectedVideoButton> createState() => _DetectedVideoButtonState();
}

class _DetectedVideoButtonState extends State<_DetectedVideoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (widget.count > 0) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _DetectedVideoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > 0 && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    }
    if (widget.count == 0 && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.value = 0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasVideo = widget.count > 0;

    return ScaleTransition(
      scale: _scale,
      child: IconButton.filledTonal(
        tooltip: hasVideo
            ? '${widget.count} video ditemukan'
            : 'Belum ada video',
        onPressed: hasVideo ? widget.onTap : null,
        icon: Badge.count(
          count: widget.count,
          isLabelVisible: hasVideo,
          child: Icon(
            LucideIcons.play,
            color: hasVideo
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _UrlTextField extends StatefulWidget {
  const _UrlTextField({
    required this.controller,
    required this.focusNode,
    required this.colorScheme,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
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
        focusNode: widget.focusNode,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
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

class DetectedVideosPage extends StatelessWidget {
  const DetectedVideosPage({super.key, required this.videos});

  final List<DetectedVideo> videos;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: _DetectedVideosHeader(videos: videos),
              ),
            ),
            if (videos.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('Belum ada video terdeteksi.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                sliver: SliverList.separated(
                  itemCount: videos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _DetectedVideoTile(
                      video: videos[index],
                      index: index,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetectedVideosHeader extends StatelessWidget {
  const _DetectedVideosHeader({required this.videos});

  final List<DetectedVideo> videos;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.arrowLeft),
              ),
              const Spacer(),
              _HeaderMetric(label: 'Items', value: '${videos.length}'),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Video siap cast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua link media yang berhasil ditangkap browser akan muncul di sini.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectedVideoTile extends StatelessWidget {
  const _DetectedVideoTile({required this.video, required this.index});

  final DetectedVideo video;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(LucideIcons.play, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    video.url.pathSegments.isNotEmpty
                        ? video.url.pathSegments.last
                        : video.url.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                _QualityBadge(video: video),
                _SourceBadge(source: video.source),
              ],
            ),
            const SizedBox(height: 14),
            _InfoPanel(
              children: [
                _InfoLine(label: 'Kualitas', value: video.displayQuality),
                const SizedBox(height: 10),
                _InfoLine(label: 'Resolusi', value: _resolutionText(video)),
                const SizedBox(height: 10),
                _InfoLine(label: 'Video URL', value: video.url.toString()),
                const SizedBox(height: 10),
                _InfoLine(
                  label: 'Halaman',
                  value: video.pageUrl?.toString() ?? '-',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyUrl(context, video.url.toString()),
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: const Text('Copy URL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.cast, size: 16),
                    label: const Text('Cast'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyUrl(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('URL video disalin')));
  }

  String _resolutionText(DetectedVideo video) {
    final width = video.width;
    final height = video.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return video.displayQuality == 'Adaptive' ? 'Adaptive stream' : 'Unknown';
    }
    return '${width}x$height';
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.video});

  final DetectedVideo video;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        video.displayQuality,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final VideoDetectionSource source;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        source.shortLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

extension on VideoDetectionSource {
  String get shortLabel {
    return switch (this) {
      VideoDetectionSource.fileExtension => 'EXT',
      VideoDetectionSource.contentType => 'TYPE',
      VideoDetectionSource.htmlMediaElement => 'HTML',
      VideoDetectionSource.javascriptFetch => 'FETCH',
    };
  }
}
