import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/sw/shared_worker.dart';

void main(List<String> args) {
  sqliteFfiWebDebugWebWorker = true; // devWarning(true);
  mainSharedWorker(args);
}
