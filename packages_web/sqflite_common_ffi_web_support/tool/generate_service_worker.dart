import 'package:process_run/shell.dart';

Future<void> main(List<String> args) async {
  await run('webdev build');
}
