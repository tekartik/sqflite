import 'dart:async';

import 'package:sqflite_common/src/sqflite_database_factory.dart';

import 'sqlite_api.dart';

export 'package:sqflite_common/src/sqflite_database_factory.dart'
    show databaseFactory, databaseFactoryOrNull;

export 'sqlite_api.dart';

/// Open the database at a given path
///
/// It uses the global [databaseFactory]: set by the `sqflite` plugin on
/// Android, iOS and macOS. On other platforms set it first, once, typically
/// in `main()` (`databaseFactory = databaseFactoryFfi;` with
/// `sqflite_common_ffi`, `databaseFactory = databaseFactoryFfiWeb;` with
/// `sqflite_common_ffi_web`).
///
/// A relative [path] is relative to [getDatabasesPath]. Open a database once
/// and keep the returned [Database].
///
/// ```dart
/// var db = await openDatabase(
///   join(await getDatabasesPath(), 'app.db'),
///   version: 1,
///   onCreate: (db, version) async {
///     await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
///   },
/// );
/// ```
///
/// [version] (optional) specifies the schema version of the database being
/// opened. This is used to decide whether to call [onCreate], [onUpgrade],
/// and [onDowngrade]. Increment it for any schema change.
///
/// The optional callbacks are called in the following order:
///
/// 1. [onConfigure]
/// 2. [onCreate] or [onUpgrade] or [onDowngrade]
/// 3. [onOpen]
///
/// [onConfigure] is the first callback invoked when opening the database. It
/// allows you to perform database initialization such as enabling foreign keys
/// or write-ahead logging
///
/// If [version] is specified, [onCreate], [onUpgrade], and [onDowngrade] can
/// be called. These functions are mutually exclusive — only one of them can be
/// called depending on the context, although they can all be specified to
/// cover multiple scenarios. If specified, it must be a 32-bits integer greater
/// than 0. They run in a transaction: use the database they receive directly
/// (do not start a transaction) and await every call.
///
/// [onCreate] is called if the database did not exist prior to calling
/// [openDatabase]. You can use the opportunity to create the required tables
/// in the database according to your schema. It is not called for an
/// existing database.
///
/// [onUpgrade] is called if either of the following conditions are met:
///
/// 1. [onCreate] is not specified
/// 2. The database already exists and [version] is higher than the last
/// database version
///
/// In the first case where [onCreate] is not specified, [onUpgrade] is called
/// with its [OnDatabaseVersionChangeFn.oldVersion] parameter as `0`. In the second case, you can perform
/// the necessary migration procedures to handle the differing schema
///
/// [onDowngrade] is called only when [version] is lower than the last database
/// version. This is a rare case and should only come up if a newer version of
/// your code has created a database that is then interacted with by an older
/// version of your code. You should try to avoid this scenario
///
/// [onOpen] is the last optional callback to be invoked. It is called after
/// the database version has been set and before [openDatabase] returns
///
/// When [readOnly] (false by default) is true, the database is opened in
/// read-only mode: the file must exist and any write fails. [onConfigure] and
/// [onOpen] are still called. Don't specify [version]: if it differs from
/// the version of the database, the migration callback is called and saving
/// the new version fails, making the open fail.
///
/// When [singleInstance] is true (the default), a single database instance is
/// returned for a given path. Subsequent calls to [openDatabase] with the
/// same path will return the same instance, and will discard all other
/// parameters such as callbacks for that invocation. Closing it closes it for
/// every holder. This also applies to [inMemoryDatabasePath] while it is
/// open; use `singleInstance: false` to get a new private in-memory database.
///
/// If [options] is provided, all other parameters are ignored.
Future<Database> openDatabase(
  String path, {
  int? version,
  OnDatabaseConfigureFn? onConfigure,
  OnDatabaseCreateFn? onCreate,
  OnDatabaseVersionChangeFn? onUpgrade,
  OnDatabaseVersionChangeFn? onDowngrade,
  OnDatabaseOpenFn? onOpen,
  bool? readOnly = false,
  bool? singleInstance = true,
  OpenDatabaseOptions? options,
}) {
  options ??= OpenDatabaseOptions(
    version: version,
    onConfigure: onConfigure,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
    onDowngrade: onDowngrade,
    onOpen: onOpen,
    readOnly: readOnly,
    singleInstance: singleInstance,
  );
  return databaseFactory.openDatabase(path, options: options);
}

/// Open the database at a given path in read only mode
///
/// The database must exist. See [openDatabase] `readOnly` parameter.
Future<Database> openReadOnlyDatabase(
  String path, {
  bool? singleInstance = true,
}) => openDatabase(path, readOnly: true, singleInstance: singleInstance);

/// Get the default databases location.
///
/// A relative path given to [openDatabase] is relative to this location.
///
/// On Android, it is typically `data/data/<package_name>/databases`
///
/// On iOS and MacOS, it is the Documents directory.
///
/// With `sqflite_common_ffi` (Windows, Linux, Dart VM), it is
/// `.dart_tool/sqflite_common_ffi/databases` in the current directory: fine
/// for tests, not for an installed application. On the web
/// (`sqflite_common_ffi_web`), it is `/` (a path is only a name).
///
/// Note for iOS and non-Android platforms: Using `path_provider` is recommended to get the
/// databases directory. The most appropriate location on iOS would be
/// the Library directory that you could get from the `path_provider` package
/// (https://pub.dev/documentation/path_provider/latest/path_provider/getLibraryDirectory.html).
Future<String> getDatabasesPath() => databaseFactory.getDatabasesPath();

/// Delete the database at the given path.
///
/// An open instance is closed first. Prefer it to deleting the file.
Future<void> deleteDatabase(String path) =>
    databaseFactory.deleteDatabase(path);

/// Check if a database exists at a given path.
Future<bool> databaseExists(String path) =>
    databaseFactory.databaseExists(path);
