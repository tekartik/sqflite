import 'package:process_run/shell.dart';

Future<void> main() async {
  final Shell shell = Shell();

  await shell.run('''

flutter driver test_driver/main.dart

''');
}
