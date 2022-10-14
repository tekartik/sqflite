import 'dart:io';

import 'package:path/path.dart';

Future<void> main() async {
  await File(join('build', 'sw.dart.js')).copy(join('..',
      'sqflite_common_ffi_web', 'lib', 'src', 'web', 'sqflite_sw.dart.js'));
}
