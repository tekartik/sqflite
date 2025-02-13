import 'package:process_run/shell_run.dart';

Future<void> main() async {
  final shell = Shell();

  final confirmed = await promptConfirm(
    'This will create the project files if missing',
  );
  if (confirmed) {
    await shell.run('''
flutter create .
''');
  }
  await promptTerminate();
}
