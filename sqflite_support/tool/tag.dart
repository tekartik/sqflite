import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/package/package.dart';
import 'package:process_run/shell.dart';

Future main() async {
  final shell = Shell();
  final version = await getPackageVersion(dir: join('..', 'sqflite'));
  print('Version $version');
  print('Tap anything or CTRL-C: $version');

  await stdin.first;
  await shell.run('''
git tag v$version
git push origin --tags
''');
}
