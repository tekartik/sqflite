import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/import.dart';
import 'package:sqflite_common_ffi_web/src/sw/sw.dart';

/// The service worker we compile and build
void main(List<String> args) {
  sqliteFfiWebDebugWebWorker = devWarning(true);
  mainServiceWorker(args);
}
