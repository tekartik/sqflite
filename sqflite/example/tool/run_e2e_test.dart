import 'package:process_run/shell.dart';

Future<void> main() async {
  final Shell shell = Shell();

  await shell.run('''

flutter driver --driver=test_driver/sqflite_e2e_test.dart test_driver/sqflite_e2e.dart

''');
}
