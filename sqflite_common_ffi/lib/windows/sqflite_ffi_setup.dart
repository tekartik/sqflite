/// Windows setup helper.
library;

export 'package:sqflite_common_ffi/src/windows/sqflite_ffi_setup_stub.dart'
    if (dart.libary.io) 'package:sqflite_common_ffi/src/windows/sqflite_ffi_setup_io.dart';
