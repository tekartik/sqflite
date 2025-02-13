import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

import 'run_ci_ios.dart';

var appExp3Path = join('.dart_tool', 'sqflite_test', 'exp3');

Future<void> main() async {
  await createAndBuildMacos(appPath: appExp3Path);
}

Future<void> createAndBuildMacos({required String appPath}) async {
  var shell = Shell();
  var create = true;
  if (create) {
    try {
      await Directory(appPath).delete(recursive: true);
    } catch (_) {}
    await shell.run(
      'flutter create --template app --platforms macos ${shellArgument(appPath)}',
    );
  }
  shell = shell.cd(appPath);
  await fixProject(appPath);
  await shell.run('flutter build macos --debug');
}
