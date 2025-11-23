// ignore_for_file: unused_import

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'main_ffi.dart';

void main() {
  if (kIsWeb) {
    // sqliteFfiWebDebugWebWorker = true;
    // ignore: avoid_print
    print('running on the web basic worker');
  }
  mainFfi(webBasicWorker: true);
  //mainFfi();
}
