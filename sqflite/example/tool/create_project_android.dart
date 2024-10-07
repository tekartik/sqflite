import 'package:process_run/shell.dart';

Future<void> main() async {
  await createProjectAndroid();
}

Future<void> createProjectAndroid() async {
  final shell = Shell();
  await shell.run('flutter create --platforms android .');
}
