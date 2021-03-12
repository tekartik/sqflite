import 'package:path/path.dart';
import 'package:process_run/shell.dart';

/// Run unit and driver test on a connected device
Future main() async {
  var shell = Shell();

  shell = shell.pushd(join('..', 'sqflite'));
  await shell.run('''
    
    flutter test
    
        ''');

  shell = shell.pushd('example');
  await shell.run('''
    
    flutter packages get
    # flutter test
    dart tool/run_integration_test.dart
    
        ''');
  shell = shell.popd();
  shell = shell.popd();
}
