import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_example/main.dart';
import 'package:sqflite_test_app/main_ffi.dart';

Future<void> main() async {
  /// Use ffi on the web
  if (kIsWeb) {
    await initFfi();
  } else if (Platform.isWindows || Platform.isLinux) {
    await initFfi();
  } else {
    // Use regular sqflite
  }
  WidgetsFlutterBinding.ensureInitialized();
  mainExampleApp();
}
