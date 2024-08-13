import 'package:process_run/shell.dart';

Future<void> main() async {
  await run('dart pub global deactivate webdev');
}
