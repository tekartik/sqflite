import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common/sqflite_dev.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/env_utils.dart'; // ignore: implementation_imports

/// Test context for testing
abstract class SqfliteTestContext {
  bool get isPlugin;

  /// The factory.
  DatabaseFactory get databaseFactory;

  /// True if dead lock can be tested
  bool get supportsDeadLock;

  /// True if supported.
  bool get supportsWithoutRowId;

  /// True if strict implementation failing on complex queries.
  bool get strict;

  /// Delete an existing db, creates its parent folder
  Future<String> initDeleteDb(String dbName);

  /// Create a directory (null means the databases path
  Future<String> createDirectory(String? path);

  /// Delete a directory content
  Future<String> deleteDirectory(String path);

  /// Write a file content.
  Future<String> writeFile(String path, List<int> data);

  /// Check if path is in memory.
  bool isInMemoryPath(String path);

  /// path context.
  Context get pathContext;

  /// true if android
  bool get isAndroid;

  /// true if iOS
  bool get isIOS;

  /// true if MacOS
  bool get isMacOS;

  /// true if Linux
  bool get isLinux;

  /// true if Linux
  bool get isWindows;

  /// True if web
  bool get isWeb => kSqfliteIsWeb;

  /// Set debug mode on
  @Deprecated('Dev only')
  Future devSetDebugModeOn(bool on);

  /// Native (android, ios, macos) only for now
  bool get supportsRecoveredInTransaction;

  /// True if supported.
  /// Not working an Android native, working with ffi impl.
  bool get supportsUri;

  /// Only sqlite_async supports it for now
  bool get supportsConcurrentRead;
}

/// sqflite test context mixin.
mixin SqfliteTestContextMixin implements SqfliteTestContext {
  /// FFI no supports Without row id on linux
  @override
  bool get supportsWithoutRowId => false;

  @override
  bool get supportsDeadLock => false;

  @override
  bool get supportsConcurrentRead => false;

  /// FFI implementation is strict
  @override
  bool get strict => true;

  @override
  bool get isWeb => kSqfliteIsWeb;

  @override
  path.Context get pathContext => path.context;

  @override
  bool isInMemoryPath(String path) {
    return path == inMemoryDatabasePath;
  }

  @override
  Future<String> initDeleteDb(String dbName) async {
    var databasesPath = await createDirectory(null);
    // print(databasePath);
    var path = pathContext.join(databasesPath, dbName);
    await databaseFactory.deleteDatabase(path);
    return path;
  }

  @override
  Future devSetDebugModeOn(bool on) => databaseFactory
  // ignore: deprecated_member_use
  .setLogLevel(on ? sqfliteLogLevelVerbose : sqfliteLogLevelNone);

  @override
  bool get supportsRecoveredInTransaction => false;

  @override
  bool get supportsUri => false;

  @override
  bool get isPlugin => false;
}

/// sqflite local test context mixin.
mixin SqfliteLocalTestContextMixin implements SqfliteTestContext {
  @override
  Future<String> createDirectory(String? path) async {
    path = await fixDirectoryPath(path);
    try {
      await Directory(path).create(recursive: true);
    } catch (_) {}
    return path;
  }

  @override
  Future<String> deleteDirectory(String path) async {
    path = await fixDirectoryPath(path);
    try {
      await Directory(path).delete(recursive: true);
    } catch (_) {}
    return path;
  }

  @override
  Future<String> writeFile(String path, List<int> data) async {
    var databasesPath = await createDirectory(null);
    path = pathContext.join(databasesPath, path);
    await File(path).writeAsBytes(data);
    return path;
  }

  /// Fix directory path relative to the databases path if possible.
  Future<String> fixDirectoryPath(String? path) async {
    if (path == null) {
      path = await databaseFactory.getDatabasesPath();
    } else {
      if (!isInMemoryPath(path) && isRelative(path)) {
        path = pathContext.join(await databaseFactory.getDatabasesPath(), path);
      }
    }
    return path;
  }

  @override
  bool get isAndroid => !kSqfliteIsWeb && Platform.isAndroid;

  @override
  bool get isIOS => !kSqfliteIsWeb && Platform.isIOS;

  @override
  bool get isMacOS => !kSqfliteIsWeb && Platform.isMacOS;

  @override
  bool get isLinux => !kSqfliteIsWeb && Platform.isLinux;

  @override
  bool get isWindows => !kSqfliteIsWeb && Platform.isWindows;
}

/// Based local file based context.
class SqfliteLocalTestContext
    with SqfliteTestContextMixin, SqfliteLocalTestContextMixin {
  /// Local context.
  SqfliteLocalTestContext({required this.databaseFactory});

  @override
  final DatabaseFactory databaseFactory;
}
