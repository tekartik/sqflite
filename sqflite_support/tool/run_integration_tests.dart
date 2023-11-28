import 'package:process_run/shell.dart';

/// Run unit and driver test on a connected device
Future main() async {
  var shell = Shell(workingDirectory: '..');

  shell = shell.pushd('sqflite');
  await shell.run('''
    
    flutter test
    
        ''');

  shell = shell.pushd('example');
  await shell.run('''
    
    flutter packages get
    flutter test
    dart tool/run_flutter_driver_test.dart
    
        ''');
  shell = shell.popd();
  shell = shell.popd();
}
