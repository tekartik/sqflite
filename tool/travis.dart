import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('flutter doctor');

  for (var dir in [
    'sqflite/example',
    'sqflite',
    'sqflite_test_app',
  ]) {
    shell = shell.pushd(dir);
    await shell.run('''
    
    flutter packages get
    dart tool/travis.dart
    
        ''');
    shell = shell.popd();
  }

  for (var dir in [
    'sqflite_common',
    'sqflite_common_test',
    'sqflite_common_ffi',
  ]) {
    shell = shell.pushd(dir);
    await shell.run('''
    
    pub get
    dart tool/travis.dart
    
        ''');
    shell = shell.popd();
  }
}
