import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_example/utils.dart';

import 'run_integration_test.dart' as integration_test;

Future<void> main() async {
  final shell = Shell();

  await shell.run('''

flutter analyze

''');

  var exception;
  try {
    await integration_test.main();
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
