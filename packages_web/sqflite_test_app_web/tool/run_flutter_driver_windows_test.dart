import 'package:process_run/shell.dart';

Future<void> main() async {
  final shell = Shell();

  await shell.run('''

flutter driver --target=test_driver/main.dart -d windows

''');
}
