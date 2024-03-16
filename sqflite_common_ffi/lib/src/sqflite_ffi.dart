export 'sqflite_ffi_io.dart'
    if (dart.library.js_interop) 'sqflite_ffi_web.dart';

/// Signature responsible for overriding the SQLite dynamic library to use.
typedef SqfliteFfiInit = void Function();
