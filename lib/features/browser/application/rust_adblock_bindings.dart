import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

typedef _NativeShouldBlock = Bool Function(
  Pointer<Uint8> urlPtr,
  IntPtr urlLen,
  Pointer<Uint8> sourcePtr,
  IntPtr sourceLen,
  Pointer<Uint8> requestTypePtr,
  IntPtr requestTypeLen,
);

typedef _DartShouldBlock = bool Function(
  Pointer<Uint8> urlPtr,
  int urlLen,
  Pointer<Uint8> sourcePtr,
  int sourceLen,
  Pointer<Uint8> requestTypePtr,
  int requestTypeLen,
);

class RustAdBlockBindings {
  RustAdBlockBindings._(this._shouldBlock);

  final _DartShouldBlock _shouldBlock;

  static RustAdBlockBindings? tryLoad() {
    try {
      final library = DynamicLibrary.open(_libraryName);
      return RustAdBlockBindings._(
        library
            .lookupFunction<_NativeShouldBlock, _DartShouldBlock>(
              'marlin_adblock_should_block',
            ),
      );
    } on Object {
      return null;
    }
  }

  bool shouldBlock({
    required Uri url,
    required Uri sourceUrl,
    String requestType = 'other',
  }) {
    final urlBytes = Uint8List.fromList(url.toString().codeUnits);
    final sourceBytes = Uint8List.fromList(sourceUrl.toString().codeUnits);
    final typeBytes = Uint8List.fromList(requestType.codeUnits);

    final urlPtr = malloc<Uint8>(urlBytes.length);
    final sourcePtr = malloc<Uint8>(sourceBytes.length);
    final typePtr = malloc<Uint8>(typeBytes.length);

    try {
      urlPtr.asTypedList(urlBytes.length).setAll(0, urlBytes);
      sourcePtr.asTypedList(sourceBytes.length).setAll(0, sourceBytes);
      typePtr.asTypedList(typeBytes.length).setAll(0, typeBytes);

      return _shouldBlock(
        urlPtr,
        urlBytes.length,
        sourcePtr,
        sourceBytes.length,
        typePtr,
        typeBytes.length,
      );
    } finally {
      malloc.free(urlPtr);
      malloc.free(sourcePtr);
      malloc.free(typePtr);
    }
  }

  static String get _libraryName {
    if (Platform.isAndroid || Platform.isLinux) {
      return 'libmarlin_cast_rust.so';
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return 'libmarlin_cast_rust.dylib';
    }
    if (Platform.isWindows) {
      return 'marlin_cast_rust.dll';
    }
    return 'marlin_cast_rust';
  }
}
