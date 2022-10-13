import 'dart:io';

import 'package:sqflite_example/main.dart';

import 'main_ffi.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    mainFfi();
    return;
  } else {
    mainExampleApp();
  }
}
