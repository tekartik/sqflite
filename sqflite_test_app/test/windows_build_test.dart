@TestOn('vm')
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';

Future<void> main() async {
  test('buildWindows', () async {
    var exeDir = join('build', 'windows', 'runner', 'Release');
    var exePath = join(exeDir, 'sqflite_test_app.exe');
    var cachedExePath = join(exeDir, 'ffi_create_and_exit.exe');
    var absoluteExePath = absolute(cachedExePath);
    // If you change the app code, you must delete the built executable since it
    // since it won't rebuild
    var shell = Shell();
    if (!File(absoluteExePath).existsSync()) {
      // Delete existing windows project
      try {
        await Directory('windows').delete(recursive: true);
      } catch (_) {}
      await shell.run('''
    # needed only once
    flutter config --enable-windows-desktop
    
    # Create windows project
    flutter create --platforms windows .
    flutter build windows --target test/ffi_create_and_exit_main.dart
    ''');
      // Cache executable
      await File(exePath).copy(cachedExePath);
    }
    // Create an empty shell environment
    var env = ShellEnvironment.empty();
    var runAppShell = Shell(
        environment: env,
        workingDirectory: join('build', 'windows', 'runner', 'Release'));
    // Should fail (missing sqlite3)
    try {
      await File(join(exeDir, 'sqlite3.dll')).delete();
    } catch (_) {}

    try {
      try {
        await runAppShell.run(shellArgument(absoluteExePath));
        fail('should fail');
      } on ShellException catch (_) {}
    } catch (e) {
      // ignore: avoid_print
      print('This should fail but succeed on github...');
    }

    var dbFile = join(exeDir, '.local', 'databases', 'example.db');
    try {
      await File(dbFile).delete();
    } catch (_) {}

    await File(findWindowsDllPath()!).copy(join(exeDir, 'sqlite3.dll'));

    expect(File(dbFile).existsSync(), isFalse);
    await runAppShell.run(shellArgument(absoluteExePath));
    expect(File(dbFile).existsSync(), isTrue);
  }, skip: !isWindows, timeout: const Timeout(Duration(minutes: 10)));
}
