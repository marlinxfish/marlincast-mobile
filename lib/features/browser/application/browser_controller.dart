import 'package:flutter/foundation.dart';

import '../domain/detected_video.dart';
import 'ad_block_engine.dart';
import 'video_sniffer.dart';

class BrowserController extends ChangeNotifier {
  BrowserController({
    AdBlockEngine? adBlockEngine,
    VideoSniffer? videoSniffer,
  }) : _adBlockEngine = adBlockEngine ?? _createAdBlockEngine(),
       _videoSniffer = videoSniffer ?? VideoSniffer();

  final AdBlockEngine _adBlockEngine;
  final VideoSniffer _videoSniffer;

  DetectedVideo? _detectedVideo;
  int _blockedAds = 0;
  double _progress = 0;
  Uri _currentUrl = Uri.parse('https://google.com');

  DetectedVideo? get detectedVideo => _detectedVideo;
  int get blockedAds => _blockedAds;
  double get progress => _progress;
  Uri get currentUrl => _currentUrl;
  bool get hasDetectedVideo => _detectedVideo != null;

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
    String? contentType,
  }) {
    final detected = _videoSniffer.inspect(url: url, contentType: contentType);
    if (detected != null && detected.url != _detectedVideo?.url) {
      _detectedVideo = detected;
      notifyListeners();
    }
    return detected;
  }

  void clearDetectedVideo() {
    _detectedVideo = null;
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
