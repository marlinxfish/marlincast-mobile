import '../domain/detected_video.dart';

class VideoSniffer {
  static const _videoExtensions = {
    '.mp4',
    '.m3u8',
    '.mpd',
    '.m4v',
    '.mov',
    '.webm',
    '.mkv',
    '.avi',
    '.ts',
  };

  static const _videoQueryTerms = {
    'mime=video',
    'type=video',
    'video/mp4',
    'video%2fmp4',
    'application/vnd.apple.mpegurl',
    'mpegurl',
    'dash',
  };

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

    final query = url.query.toLowerCase();
    final hasVideoQuery = _videoQueryTerms.any(query.contains);
    if (hasVideoQuery) {
      return DetectedVideo(url: url, source: VideoDetectionSource.fileExtension);
    }

    return null;
  }
}
