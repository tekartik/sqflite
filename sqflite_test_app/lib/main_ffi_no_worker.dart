// ignore_for_file: unused_import

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_example_common/main.dart';

import 'main_ffi.dart';

void main() {
  // ignore: avoid_print
  print('running without worker');
  // debugAutoStartRouteName = testOpenRoute;
  mainFfi(noWorker: true);
}
