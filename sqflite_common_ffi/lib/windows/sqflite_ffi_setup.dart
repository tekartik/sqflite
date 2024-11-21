/// Windows setup helper.
library;

export 'package:sqflite_common_ffi/src/windows/sqflite_ffi_setup_stub.dart'
    if (dart.library.io) 'package:sqflite_common_ffi/src/windows/sqflite_ffi_setup_io.dart';
