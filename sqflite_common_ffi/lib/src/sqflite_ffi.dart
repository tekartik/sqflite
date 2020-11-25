export 'sqflite_ffi_stub.dart' if (dart.library.io) 'sqflite_ffi_io.dart';

/// Signature responsible for overriding the SQLite dynamic library to use.
typedef SqfliteFfiInit = void Function();
