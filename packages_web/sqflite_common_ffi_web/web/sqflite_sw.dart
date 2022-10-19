import 'package:sqflite_common_ffi_web/src/sw/shared_worker.dart';

/// The shared worker we compile and build
void main(List<String> args) {
  // sqliteFfiWebDebugWebWorker = devWarning(true);
  mainSharedWorker(args);
}
