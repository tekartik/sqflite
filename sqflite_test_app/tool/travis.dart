import 'package:process_run/shell_run.dart';

Future<void> main() async {
  final shell = Shell();

  await shell.run('''

flutter format --set-exit-if-changed lib test tool
flutter analyze --no-current-package lib test tool
flutter test --no-pub --coverage

''');
}
