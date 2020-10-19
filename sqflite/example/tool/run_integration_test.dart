import 'package:process_run/shell.dart';

Future<void> main() async {
  final shell = Shell();

  await shell.pushd('android').run('flutter drive'
      ' --driver=test_driver/integration_test.dart'
      ' --target=integration_test/sqflite_test.dart');
}
