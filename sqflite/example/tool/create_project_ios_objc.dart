import 'package:process_run/shell.dart';

Future<void> main() async {
  await createProjectIosObjc();
}

Future<void> createProjectIosObjc() async {
  final shell = Shell();
  await shell.run('flutter create --platforms ios -i objc .');
}
