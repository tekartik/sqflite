import 'package:process_run/shell.dart';

Future<void> main(List<String> args) async {
  await run('''
      dart pub get
      webdev serve example:8060
  ''');
}
