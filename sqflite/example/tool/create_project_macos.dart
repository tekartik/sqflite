import 'package:process_run/shell.dart';

Future<void> main() async {
  await createProjectMacos();
}

Future<void> createProjectMacos() async {
  final shell = Shell();
  await shell.run('flutter create --platforms macos .');
}
