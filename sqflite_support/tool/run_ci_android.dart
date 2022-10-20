import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

late String workDir;
String get workAndroidDir => join(workDir, 'android');

Future main() async {
  workDir = join('..', 'sqflite', 'example');
  await buildApk();
  await runAndroidTest();
  workDir = join('..', 'sqflite_test_app');
  await createAndroidProject();
  await buildApk();
  await runAndroidTest();
}

Future<void> buildApk() async {
  var shell = Shell(workingDirectory: workDir);
  await shell.run('flutter build apk');
}

Future<void> runAndroidTest() async {
  var shell = Shell(workingDirectory: workAndroidDir);
  await shell.run('./gradlew test');
}

Future<void> createAndroidProject() async {
  try {
    await Directory(workAndroidDir).delete(recursive: true);
  } catch (_) {}
  await run('flutter create --platforms android ${shellArgument(workDir)}');
}
