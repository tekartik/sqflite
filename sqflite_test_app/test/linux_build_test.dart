@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_test_app/src/ffi_test_utils.dart';

var runningOnGithubAction = Platform.environment['GITHUB_ACTION'] != null;

Future<void> main() async {
  var appFilename = await getBuildProjectAppFilename('.');
  var exeDir = platformExeDir;
  var exePath = join(exeDir, appFilename);
  test('build $platform', () async {
    var cachedExePath = join(exeDir, 'ffi_create_and_exit');
    var absoluteExePath = absolute(cachedExePath);

    // If you change the app code, you must delete the built executable since it
    // since it won't rebuild
    if (!File(absoluteExePath).existsSync()) {
      await createProject('.');
      await buildProject('.', target: 'test/ffi_create_and_exit_main.dart');

      // Cache executable
      await File(exePath).copy(cachedExePath);
    }
    // Create an empty shell environment
    var env = ShellEnvironment.empty();
    var runAppShell = Shell(environment: env, workingDirectory: exeDir);

    var dbFile = join(exeDir, '.local', 'databases', 'example.db');
    try {
      await File(dbFile).delete();
    } catch (_) {}

    expect(File(dbFile).existsSync(), isFalse);

    /// Failing due to GTK issue on github
    if (!runningOnGithubAction) {
      await runAppShell.run(join('.', appFilename));
      expect(File(dbFile).existsSync(), isTrue);
    }
  }, skip: !platformIsLinux, timeout: const Timeout(Duration(minutes: 10)));
}
