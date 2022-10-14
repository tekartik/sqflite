import 'package:process_run/shell.dart';

Future<void> main(List<String> args) async {
  await run('webdev serve web:8060');
}
