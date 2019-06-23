import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_example/utils.dart';

import 'run_flutter_driver_test.dart' as driver;

Future<void> main() async {
  final Shell shell = Shell();

  await shell.run('''

flutter analyze
flutter test

''');

  var exception;
  try {
    await driver.main();
  } catch (e) {
    exception = e;
  }

  // For android look for some kind of generated file
  if (await Directory(join('build', 'sqflite', 'generated')).exists()) {
    if (exception != null) {
      throw exception;
    }
  }
}
