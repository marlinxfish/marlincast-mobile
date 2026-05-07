class DetectedVideo {
  const DetectedVideo({
    required this.url,
    required this.source,
    this.pageUrl,
    this.detectedAt,
    this.width,
    this.height,
    this.qualityLabel,
  });

  final Uri url;
  final VideoDetectionSource source;
  final Uri? pageUrl;
  final DateTime? detectedAt;
  final int? width;
  final int? height;
  final String? qualityLabel;

  String get displayQuality {
    final label = qualityLabel;
    if (label != null && label.isNotEmpty) {
      return label;
    }

    final videoHeight = height;
    if (videoHeight != null && videoHeight > 0) {
      return '${videoHeight}p';
    }

    if (_isAdaptiveUrl(url)) {
      return 'Adaptive';
    }

    return 'Unknown';
  }

  static bool _isAdaptiveUrl(Uri url) {
    final value = url.toString().toLowerCase();
    return value.contains('.m3u8') || value.contains('.mpd');
  }
}

enum VideoDetectionSource {
  fileExtension,
  contentType,
  htmlMediaElement,
  javascriptFetch,
}
