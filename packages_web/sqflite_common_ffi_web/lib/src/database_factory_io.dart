import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web only - Create the proper factory based on the settings
DatabaseFactory createDatabaseFactoryFfiWeb({
  SqfliteFfiWebOptions? options,
  bool noWebWorker = false,
  String? tag,
}) => throw UnsupportedError('createDatabaseFactoryFfiWebnot supported in io');
