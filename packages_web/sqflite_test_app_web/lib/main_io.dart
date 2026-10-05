import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:sqflite_example_common/main.dart';

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
