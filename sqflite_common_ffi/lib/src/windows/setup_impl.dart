// Copied and adapted from dev_test
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

/// Read json file
Map<String, Object?> pathGetJson(String path) {
  var content = File(path).readAsStringSync();
  try {
    return (jsonDecode(content) as Map).cast<String, Object?>();
  } catch (e) {
    print('error in $path $e');
    rethrow;
  }
}

/// Read package_config.json
Map<String, Object?> pathGetPackageConfigMap(String packageDir) =>
    pathGetJson(join(packageDir, '.dart_tool', 'package_config.json'));

/// Build a file path.
String _toFilePath(String parent, String path, {bool? windows}) {
  var uri = Uri.parse(path);
  path = uri.toFilePath(windows: windows);
  if (isRelative(path)) {
    return normalize(join(parent, path));
  }
  return normalize(path);
}

/// Get a library path, you can get the project dir through its parent
String? pathPackageConfigMapGetPackagePath(
    String path, Map packageConfigMap, String package,
    {bool? windows}) {
  var packagesList = packageConfigMap['packages'];
  for (var packageMap in packagesList) {
    if (packageMap is Map) {
      var name = packageMap['name'];

      if (name is String && name == package) {
        var rootUri = packageMap['rootUri'];
        if (rootUri is String) {
          // rootUri if relative is relative to .dart_tool
          // we want it relative to the root project.
          // Replace .. with . to avoid going up twice
          if (rootUri.startsWith('..')) {
            rootUri = rootUri.substring(1);
          }
          return _toFilePath(path, rootUri, windows: windows);
        }
      }
    }
  }
  return null;
}
