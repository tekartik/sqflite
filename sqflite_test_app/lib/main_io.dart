import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:sqflite_example/main.dart';

import 'main_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    mainFfi();
    return;
  } else {
    mainExampleApp();
  }
}
