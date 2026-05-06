import 'package:file_picker/file_picker.dart';

import '../domain/local_media_file.dart';

class LocalMediaPicker {
  static const allowedExtensions = [
    'mp4',
    'm3u8',
    'mkv',
    'mov',
    'webm',
    'avi',
  ];

  Future<List<LocalMediaFile>> pickVideos() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: false,
    );

    if (result == null) {
      return const [];
    }

    return result.files.map(_fromPlatformFile).toList(growable: false);
  }

  LocalMediaFile _fromPlatformFile(PlatformFile file) {
    final extension = (file.extension ?? '').toLowerCase();
    return LocalMediaFile(
      name: file.name,
      path: file.path,
      sizeBytes: file.size,
      extension: extension,
    );
  }
}
