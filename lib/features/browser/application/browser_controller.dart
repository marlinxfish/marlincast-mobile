import 'package:flutter/foundation.dart';

import '../domain/detected_video.dart';
import 'ad_block_engine.dart';
import 'video_sniffer.dart';

class BrowserController extends ChangeNotifier {
  BrowserController({AdBlockEngine? adBlockEngine, VideoSniffer? videoSniffer})
    : _adBlockEngine = adBlockEngine ?? _createAdBlockEngine(),
      _videoSniffer = videoSniffer ?? VideoSniffer();

  final AdBlockEngine _adBlockEngine;
  final VideoSniffer _videoSniffer;

  final List<DetectedVideo> _detectedVideos = [];
  int _blockedAds = 0;
  double _progress = 0;
  Uri _currentUrl = Uri.parse('https://google.com');

  DetectedVideo? get detectedVideo => _detectedVideos.lastOrNull;
  List<DetectedVideo> get detectedVideos => List.unmodifiable(_detectedVideos);
  int get blockedAds => _blockedAds;
  double get progress => _progress;
  Uri get currentUrl => _currentUrl;
  bool get hasDetectedVideo => _detectedVideos.isNotEmpty;

  void setProgress(double value) {
    _progress = value.clamp(0, 1);
    notifyListeners();
  }

  void setCurrentUrl(Uri url) {
    _currentUrl = url;
    notifyListeners();
  }

  Future<bool> shouldBlock({
    required Uri url,
    required Uri sourceUrl,
    String requestType = 'other',
  }) async {
    final blocked = await _adBlockEngine.shouldBlock(
      url: url,
      sourceUrl: sourceUrl,
      requestType: requestType,
    );
    if (blocked) {
      _blockedAds++;
      notifyListeners();
    }
    return blocked;
  }

  DetectedVideo? inspectVideo({
    required Uri url,
    required Uri pageUrl,
    String? contentType,
  }) {
    final detected = _videoSniffer.inspect(url: url, contentType: contentType);
    if (detected != null &&
        !_detectedVideos.any((video) => video.url == detected.url)) {
      _detectedVideos.add(
        DetectedVideo(
          url: detected.url,
          source: detected.source,
          pageUrl: pageUrl,
          detectedAt: DateTime.now(),
        ),
      );
      notifyListeners();
    }
    return detected;
  }

  void addDetectedVideo({
    required Uri url,
    required Uri pageUrl,
    required VideoDetectionSource source,
    int? width,
    int? height,
    String? qualityLabel,
    Uri? thumbnailUrl,
  }) {
    if (_detectedVideos.any((video) => video.url == url)) {
      return;
    }

    _detectedVideos.add(
      DetectedVideo(
        url: url,
        source: source,
        pageUrl: pageUrl,
        detectedAt: DateTime.now(),
        width: width,
        height: height,
        qualityLabel: qualityLabel,
        thumbnailUrl: thumbnailUrl,
      ),
    );
    notifyListeners();
  }

  void clearDetectedVideo() {
    _detectedVideos.clear();
    notifyListeners();
  }

  static AdBlockEngine _createAdBlockEngine() {
    final rustEngine = RustAdBlockEngine();
    if (rustEngine.isAvailable) {
      return rustEngine;
    }
    return RuleBasedAdBlockEngine();
  }
}
