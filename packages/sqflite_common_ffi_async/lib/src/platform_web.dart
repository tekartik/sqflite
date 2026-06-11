import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_factory_web.dart';

/// The Ffi database factory.
DatabaseFactory get databaseFactoryFfiAsync => databaseFactoryFfiAsyncWebImpl;

/// The Ffi database factory for tests.
DatabaseFactory get databaseFactoryFfiAsyncTest =>
    databaseFactoryFfiAsyncWebTestImpl;
