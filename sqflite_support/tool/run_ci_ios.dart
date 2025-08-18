import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

var appExp1Path = join('.dart_tool', 'sqflite_test', 'exp1');

Future<void> main() async {
  await createAndBuildIos(appPath: appExp1Path);
}

Future<void> createAndBuildIos({required String appPath}) async {
  var shell = Shell();

  try {
    await Directory(appPath).delete(recursive: true);
  } catch (_) {}
  await shell.run(
    'flutter create --template app --platforms ios ${shellArgument(appPath)}',
  );

  shell = shell.cd(appPath);
  await fixProject(appPath);
  await shell.run('flutter build ios --debug --no-codesign');
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
