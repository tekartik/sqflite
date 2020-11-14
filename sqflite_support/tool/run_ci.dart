import 'package:process_run/shell.dart';
import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  // await packageRunCi('.');

  var shell = Shell().cd('..');

  await shell.run('flutter doctor');

  for (var dir in [
    '.',
    ...[
      'sqflite_common',
      // 'sqflite_common_test',
      // 'sqflite_common_ffi',
    ].map((dir) => join('..', dir))
  ]) {
    await packageRunCi(dir);
  }
}
