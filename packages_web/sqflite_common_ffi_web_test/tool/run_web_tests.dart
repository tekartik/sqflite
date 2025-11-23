import 'package:process_run/shell.dart';

Future<void> main() async {
  await runWebTests();
}

Future<void> runWebTests() async {
  await run('dart test -p chrome');
}
