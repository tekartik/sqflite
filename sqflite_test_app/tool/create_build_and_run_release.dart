import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:sqflite_test_app/src/ffi_test_utils.dart';

Future<void> main() async {
  /// Test windows in release
  if (isSupported) {
    await createProject('.');
    await buildProject('.');

    var appName = await getBuildProjectAppFilename('.');

    if (platformIsWindows) {
      /// Copy the sqlite3.dll
      await File(
        '../sqflite_common_ffi/lib/src/windows/sqlite3.dll',
      ).copy('build/windows/runner/Release/sqlite3.dll');

      /// Set the current dir somewhere else
      await Shell(
        workingDirectory: Directory.systemTemp.path,
      ).run(absolute('build/windows/runner/Release/$appName'));
    } else if (platformIsLinux) {
      var exePath = absolute('build/linux/x64/release/bundle/sqflite_test_app');

      // Linux
      await Shell(workingDirectory: dirname(exePath)).run(join('.', appName));
    } else if (platformIsMacOS) {
      // MacOS
      await Shell(
        workingDirectory: platformExeDir,
      ).run('sqflite_test_app.app/Contents/MacOS/sqflite_test_app');
    }
  }
}
