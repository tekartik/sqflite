// ignore_for_file: unused_import

import 'package:sqflite_common_ffi_web/src/import.dart';

/// For testing.
var _sqliteFfiWebDebugWebWorker = false; // devWarning(true);

/// Testing only.
bool get sqliteFfiWebDebugWebWorker => _sqliteFfiWebDebugWebWorker;

/// Testing only.
@Deprecated('testing only')
set sqliteFfiWebDebugWebWorker(bool value) {
  _sqliteFfiWebDebugWebWorker = value;
}
