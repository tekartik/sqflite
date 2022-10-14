import 'dart:io';

import 'package:process_run/shell.dart';

Future<void> main(List<String> args) async {
  var buildDir = Directory('build');
  await buildDir.delete(recursive: true);
  await run('webdev build --clean');
}
