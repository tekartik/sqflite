import 'package:flutter/material.dart';
import 'package:sqflite_example/main.dart' as example;
import 'package:sqflite_example/utils.dart';

import 'main_ffi.dart' as main_ffi;

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    main_ffi.main();
    return;
  } else {
    WidgetsFlutterBinding.ensureInitialized();
    example.main();
  }
}
