import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('flutter doctor');

  for (var dir in [
    'sqflite/example',
    'sqflite',
  ]) {
    shell = shell.pushd(dir);
    await shell.run('''
    
    flutter packages get
    dart tool/travis.dart
    
        ''');
    shell = shell.popd();
  }
}
