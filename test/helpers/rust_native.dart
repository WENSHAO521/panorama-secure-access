import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;
import 'package:rust_api/rust_api.dart' show RustLib;

const _libraryStem = 'rust_api';

String get _libraryFile {
  if (Platform.isWindows) return '$_libraryStem.dll';
  if (Platform.isMacOS) return 'lib$_libraryStem.dylib';
  return 'lib$_libraryStem.so';
}

// `flutter test` runs the build hooks and copies their output to
// build/native_assets/<os>/; other flutter commands leave it in .dart_tool/lib.
List<String> get _libraryCandidates => [
  'build/native_assets/${Platform.operatingSystem}/$_libraryFile',
  '.dart_tool/lib/$_libraryFile',
];

Future<void>? _nativeInit;

Future<void> initRustNative() => _nativeInit ??= () async {
  final overrideDir =
      Platform.environment['FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR'];
  if (overrideDir != null) return RustLib.init();
  final path = _libraryCandidates.firstWhere(
    (path) => File(path).existsSync(),
    orElse: () => throw StateError(
      'rust_api native library not found; tried'
      ' ${_libraryCandidates.join(', ')} from ${Directory.current.path}. Keep'
      ' the rust_api build_assets user-define on, or set'
      ' FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR to a directory holding'
      ' the library.',
    ),
  );
  await RustLib.init(
    externalLibrary: ExternalLibrary.open(File(path).absolute.path),
  );
}();
