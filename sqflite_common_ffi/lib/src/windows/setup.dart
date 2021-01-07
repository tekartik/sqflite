import 'dart:ffi';
import 'dart:io';

import 'package:sqflite_common_ffi/src/import.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/src/windows/setup_impl.dart';

/// Windows specific sqflite3 initialization.
///
/// In debug mode: A bundled sqlite3.dll from the sqflite_common_ffi package
/// is loaded.
///
/// In release mode: sqlite3.dll is needed next to the executable.
///
/// This code is only provided for reference. See package [`sqlite3`](https://pub.dev/packages/sqlite3)
/// for more information.
void windowsInit() {
  if (isDebug) {
    var location = findPackagePath(Directory.current.path)!;
    var path = normalize(join(location, 'src', 'windows', 'sqlite3.dll'));
    open.overrideFor(OperatingSystem.windows, () {
      // devPrint('loading $path');
      try {
        return DynamicLibrary.open(path);
      } catch (e) {
        stderr.writeln('Failed to load sqlite3.dll at $path');
        rethrow;
      }
    });
  }

  // Force an open in the main isolate
  // Loading from an isolate seems to break on windows
  sqlite3.openInMemory().dispose();
}
