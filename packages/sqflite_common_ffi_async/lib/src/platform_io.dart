import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_factory.dart';

/// The Ffi database factory.
DatabaseFactory get databaseFactoryFfiAsync => databaseFactoryFfiAsyncImpl;
DatabaseFactory get databaseFactoryFfiAsyncTest =>
    databaseFactoryFfiAsyncTestImpl;
