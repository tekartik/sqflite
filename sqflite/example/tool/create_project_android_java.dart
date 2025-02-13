import 'package:process_run/shell.dart';

Future<void> main() async {
  await createProjectAndroidJava();
}

Future<void> createProjectAndroidJava() async {
  final shell = Shell();
  await shell.run(
    'flutter create --platforms android --android-language java .',
  );
}
