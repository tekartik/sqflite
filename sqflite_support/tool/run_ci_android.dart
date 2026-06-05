import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

late String workDir;
String get workAndroidDir => join(workDir, 'android');
var appExpAndroid1Path = join('.dart_tool', 'sqflite_test', 'expandroid1');

Future main() async {
  await createAddSqfliteAndBuildAndroid(appPath: appExpAndroid1Path);
  workDir = join('..', 'sqflite_android', 'example');
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

Future<void> createAddSqfliteAndBuildAndroid({required String appPath}) async {
  var shell = Shell();

  try {
    await Directory(appPath).delete(recursive: true);
  } catch (_) {}
  await shell.run(
    'flutter create --template app --platforms android ${shellArgument(appPath)}',
  );

  shell = shell.cd(appPath);
  await fixProject(appPath);
  await shell.run('flutter build apk');
}

Future<void> fixProject(String appPath) async {
  var shell = Shell().cd(appPath);
  await shell.run(
    'flutter pub add sqflite_example --path ../../../../sqflite/example',
  );
  await addDepOverrides(appPath);
}

Future<void> addDepOverrides(String appPath) async {
  var overrides = '''
dependency_overrides:
  sqflite:
    path: ../../../../sqflite
  sqflite_common:
    path: ../../../../sqflite_common
''';

  var pubspecFile = File(join(appPath, 'pubspec.yaml'));
  var content = await pubspecFile.readAsString();
  content = '$content\n$overrides';
  await pubspecFile.writeAsString(content);
}
