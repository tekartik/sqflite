import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/src/windows/setup_impl.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

/// Get the dll path from our package path.
String packageGetSqlite3DllPath(String packagePath) {
  var path = join(packagePath, 'src', 'windows', 'sqlite3.dll');
  return path;
}

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
  // Look for the bundle sqlite3.dll while in development
  // otherwise make sure to copy the dll along with the executable
  var path = findWindowsDllPath();
  if (path != null) {
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

/// Find sqflite_common_ffi path
String? findPackageLibPath(String path) {
  var map = pathGetPackageConfigMap(path);

  var packagePath =
      pathPackageConfigMapGetPackagePath(path, map, 'sqflite_common_ffi');
  if (packagePath != null) {
    return join(packagePath, 'lib');
  }
  return null;
}

/// Find windows dll path.
String? findWindowsDllPath() {
  var location = findPackageLibPath(Directory.current.path);
  if (location != null) {
    var path = packageGetSqlite3DllPath(normalize(join(location)));
    return path;
  }
  return null;
}
