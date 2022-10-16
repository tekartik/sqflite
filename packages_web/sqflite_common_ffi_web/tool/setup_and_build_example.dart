import 'package:process_run/shell.dart';

import 'setup_example.dart';

Future<void> main(List<String> args) async {
  await setupExample();
  await run('''
      dart pub get
      webdev build -o example:build
  ''');
}
