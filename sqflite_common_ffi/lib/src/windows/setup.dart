import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart' as foundation;
import 'package:moor_ffi/database.dart';
import 'package:moor_ffi/open_helper.dart';
import 'package:path/path.dart';

/// On windows load the embedded sqlite3.dll for convenience
void windowsInit() {
  String rootPath;
  if (foundation.kDebugMode) {
    rootPath = 'build';
  } else {
    rootPath = 'data';
  }
  var location = Directory.current.path;
  String path = normalize(join(location, rootPath, 'flutter_assets', 'packages', 'sqflite_common_ffi', 'assets', 'sqlite3.dll'));
  
  open.overrideFor(OperatingSystem.windows, () {
    // devPrint('loading $path');
    try {
      return DynamicLibrary.open(path);
    } catch (e) {
      stderr.writeln('Failed to load sqlite3.dll at $path');
      rethrow;
    }
  });

  // Force an open in the main isolate
  // Loading from an isolate seems to break on windows
  Database.memory()..close();
}
