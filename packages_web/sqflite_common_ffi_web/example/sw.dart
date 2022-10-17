import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/sw/sw.dart';

//var globals = newModel();
void main(List<String> args) {
  sqliteFfiWebDebugWebWorker = true; // devWarning(true);
  mainServiceWorker(args);
}
