import 'package:process_run/shell.dart';

Future<void> main() async {
  await run('dart test -p chrome');
}
