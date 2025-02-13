import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/src/windows/setup_impl.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

/// Local info file name.
const sqflite3InfoJsonFileName = 'sqflite3_info.json';

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

/// Find sqflite_common_ffi path from a repository path
///
/// Return null if not found
String? findPackageLibPath(String path) {
  try {
    var map = pathGetPackageConfigMap(path);
    var packagePath = pathPackageConfigMapGetPackagePath(
      path,
      map,
      'sqflite_common_ffi',
    );
    if (packagePath != null) {
      return join(packagePath, 'lib');
    }
  } catch (_) {}
  return null;
}

/// Secret trick to find the windows dll path from a given path
/// It looks for a parent (or same directory) pubspec.lock file
/// to resolve the sqflite_common_ffi package
String? findWindowsSqlite3DllPathFromPath(String path) {
  try {
    path = normalize(absolute(path));
    var packageTopPath = findCurrentPackageTopPath(path);
    if (packageTopPath != null) {
      var libPath = findPackageLibPath(packageTopPath);
      if (libPath != null) {
        var sqlite3DllPath = packageGetSqlite3DllPath(libPath);
        if (File(sqlite3DllPath).existsSync()) {
          return sqlite3DllPath;
        }
      }
    }
  } catch (_) {}
  return null;
}

///
/// checking recursively to find a valid parent directory
///
String? pathFindTopLevelPath(
  String path, {
  required bool Function(String path) pathIsTopLevel,
}) {
  path = normalize(absolute(path));
  String parent;
  while (true) {
    if (FileSystemEntity.isDirectorySync(path)) {
      if (pathIsTopLevel(path)) {
        return path;
      }
    }
    parent = dirname(path);
    if (parent == path) {
      break;
    }
    path = parent;
  }
  return null;
}

/// Look for pubspec.lock file
/// Which seems the safest to handle package in global pub too
String? findCurrentPackageTopPath(String path) {
  return pathFindTopLevelPath(
    path,
    pathIsTopLevel: (path) {
      var lockFile = File(join(path, 'pubspec.lock'));
      if (lockFile.existsSync()) {
        return true;
      }
      return false;
    },
  );
}

/// Compat
String? findWindowsDllPath() => findWindowsSqlite3DllPath();

/// Find windows dll path.
String? findWindowsSqlite3DllPath() {
  /// Try to look from the current path
  /// Handles and dart script ran withing a project importing sqflite_common_ffi
  var dllPath = findWindowsSqlite3DllPathFromPath(Directory.current.path);
  if (dllPath != null) {
    return dllPath;
  }

  /// Try to look from the script path, handles script using global run
  dllPath = findWindowsSqlite3DllPathFromPath(Platform.script.toFilePath());
  if (dllPath != null) {
    return dllPath;
  }

  return null;
}
