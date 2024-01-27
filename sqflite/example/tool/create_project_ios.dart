import 'package:process_run/shell.dart';

Future<void> main() async {
  await createProjectIos();
}

Future<void> createProjectIos() async {
  final shell = Shell();
  await shell.run('flutter create --platforms ios .');
}
