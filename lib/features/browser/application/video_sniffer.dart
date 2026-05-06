import '../domain/detected_video.dart';

class VideoSniffer {
  static const _videoExtensions = {'.mp4', '.m3u8', '.ts'};

  DetectedVideo? inspect({
    required Uri url,
    String? contentType,
  }) {
    final normalizedContentType = contentType?.toLowerCase();
    if (normalizedContentType != null &&
        normalizedContentType.startsWith('video/')) {
      return DetectedVideo(url: url, source: VideoDetectionSource.contentType);
    }

    final path = url.path.toLowerCase();
    final hasVideoExtension = _videoExtensions.any(path.endsWith);
    if (hasVideoExtension) {
      return DetectedVideo(url: url, source: VideoDetectionSource.fileExtension);
    }

    return null;
  }
}
