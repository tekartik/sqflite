import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

/// Build a file path.
String toFilePath(String parent, String path, {bool windows}) {
  var uri = Uri.parse(path);
  path = uri.toFilePath(windows: windows);
  if (isRelative(path)) {
    return normalize(join(parent, path));
  }
  return normalize(path);
}

/// Find our package path in the current project
String findPackagePath(String currentPath, {bool windows}) {
  String findPath(File file) {
    var lines = LineSplitter.split(file.readAsStringSync());
    for (var line in lines) {
      var parts = line.split(':');
      if (parts.length > 1) {
        if (parts[0] == 'sqflite_common_ffi') {
          var location = parts.sublist(1).join(':');
          return absolute(normalize(
              toFilePath(dirname(file.path), location, windows: windows)));
        }
      }
    }
    return null;
  }

  var file = File(join(currentPath, '.packages'));
  if (file.existsSync()) {
    return findPath(file);
  } else {
    var parent = dirname(currentPath);
    if (parent == currentPath) {
      return null;
    }
    return findPackagePath(parent);
  }
}

/// Get the dll path from our package path.
String packageGetSqlite3DllPath(String packagePath) {
  var path = join(packagePath, 'src', 'windows', 'sqlite3.dll');
  return path;
}
