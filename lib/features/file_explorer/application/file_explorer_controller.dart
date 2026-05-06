import 'package:flutter/foundation.dart';

import '../domain/local_media_file.dart';
import 'local_media_picker.dart';

class FileExplorerController extends ChangeNotifier {
  FileExplorerController({LocalMediaPicker? picker})
    : _picker = picker ?? LocalMediaPicker();

  final LocalMediaPicker _picker;

  final List<LocalMediaFile> _files = [];
  bool _isPicking = false;

  List<LocalMediaFile> get files => List.unmodifiable(_files);
  bool get isPicking => _isPicking;
  bool get hasFiles => _files.isNotEmpty;

  Future<void> pickVideos() async {
    _isPicking = true;
    notifyListeners();

    try {
      final pickedFiles = await _picker.pickVideos();
      if (pickedFiles.isNotEmpty) {
        _files
          ..clear()
          ..addAll(pickedFiles);
      }
    } finally {
      _isPicking = false;
      notifyListeners();
    }
  }

  void remove(LocalMediaFile file) {
    _files.remove(file);
    notifyListeners();
  }
}
