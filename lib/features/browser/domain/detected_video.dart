class DetectedVideo {
  const DetectedVideo({
    required this.url,
    required this.source,
  });

  final Uri url;
  final VideoDetectionSource source;
}

enum VideoDetectionSource {
  fileExtension,
  contentType,
}
