import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

Future<void> main() async {
  final shell = Shell();

  /// Test windows in release
  if (Platform.isWindows) {
    await shell.run('''
    flutter create .
    flutter config --enable-windows-desktop
    flutter build windows
    ''');

    /// Copy the sqlite3.dll
    await File('../sqflite_common_ffi/lib/src/windows/sqlite3.dll')
        .copy('build/windows/runner/Release/sqlite3.dll');

    /// Set the current dir somewhere else
    await Shell(workingDirectory: Directory.systemTemp.path)
        .run(absolute('build/windows/runner/Release/sqflite_test_app.exe'));
  }
}
