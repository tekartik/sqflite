import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/path_utils.dart';

/// Database factory sandbox extension.
extension SqfliteDatabaseFactorySandboxExtension on DatabaseFactory {
  /// Database factory sandboxing.
  ///
  /// Every database opened, deleted or checked through the returned factory
  /// is located below [path] in the original factory. [path] also becomes the
  /// value returned by [DatabaseFactory.getDatabasesPath] of the returned
  /// factory. If [path] is not specified, it defaults to the current factory
  /// databases path.
  ///
  /// Relative paths are resolved relative to the sandboxed factory databases
  /// path. Absolute paths must be inside the sandbox root, otherwise an
  /// [ArgumentError] is thrown. [inMemoryDatabasePath] is allowed and used
  /// as is.
  ///
  /// If the factory is already a sandbox, the tree is sanitized (i.e. never 2
  /// levels of sandboxing).
  ///
  /// Works with any [DatabaseFactory] implementation (sqflite, ffi, web).
  DatabaseFactory sandbox({String? path}) {
    var self = this;
    if (self is _SqfliteDatabaseFactorySandbox) {
      return _SqfliteDatabaseFactorySandbox(
        delegate: self.delegate,
        rootPathProvider: () => self._childRootPath(path),
      );
    }
    return _SqfliteDatabaseFactorySandbox(
      delegate: this,
      rootPathProvider: () async => path ?? await getDatabasesPath(),
    );
  }
}

class _SqfliteDatabaseFactorySandbox implements DatabaseFactory {
  _SqfliteDatabaseFactorySandbox({
    required this.delegate,
    required this._rootPathProvider,
  });

  /// The wrapped factory.
  final DatabaseFactory delegate;

  /// Resolves the root path, only called once.
  final Future<String> Function() _rootPathProvider;

  /// The root path of the sandbox in the delegate factory, resolved lazily.
  String? _rootPath;

  /// The current databases path, root path if never set.
  String? _databasesPath;

  Future<String> _getRootPath() async =>
      _rootPath ??= p.normalize(await _rootPathProvider());

  /// Root path for a child sandbox, [path] being in this sandbox coordinates.
  Future<String> _childRootPath(String? path) async =>
      path == null ? await getDatabasesPath() : await _delegatePath(path);

  /// Converts a path in the sandboxed factory to a path in the delegate
  /// factory. Throws an [ArgumentError] if the path escapes the sandbox.
  Future<String> _delegatePath(String path) async {
    if (isInMemoryDatabasePath(path)) {
      return path;
    }
    if (isFileUriDatabasePath(path)) {
      throw ArgumentError.value(
        path,
        'path',
        'file uri not supported in a sandboxed factory',
      );
    }
    var rootPath = await _getRootPath();
    var fullPath = p.isAbsolute(path)
        ? p.normalize(path)
        : p.normalize(p.join(await getDatabasesPath(), path));
    if (!p.isWithin(rootPath, fullPath)) {
      throw ArgumentError.value(
        path,
        'path',
        'Path is outside of the sandbox root $rootPath',
      );
    }
    return fullPath;
  }

  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async =>
      delegate.openDatabase(await _delegatePath(path), options: options);

  @override
  Future<String> getDatabasesPath() async =>
      _databasesPath ?? await _getRootPath();

  @override
  Future<void> setDatabasesPath(String path) async {
    var rootPath = await _getRootPath();
    var fullPath = p.isAbsolute(path)
        ? p.normalize(path)
        : p.normalize(p.join(rootPath, path));
    if (!(p.equals(rootPath, fullPath) || p.isWithin(rootPath, fullPath))) {
      throw ArgumentError.value(
        path,
        'path',
        'Path is outside of the sandbox root $rootPath',
      );
    }
    _databasesPath = fullPath;
  }

  @override
  Future<void> deleteDatabase(String path) async =>
      delegate.deleteDatabase(await _delegatePath(path));

  @override
  Future<bool> databaseExists(String path) async =>
      delegate.databaseExists(await _delegatePath(path));

  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) async =>
      delegate.writeDatabaseBytes(await _delegatePath(path), bytes);

  @override
  Future<Uint8List> readDatabaseBytes(String path) async =>
      delegate.readDatabaseBytes(await _delegatePath(path));

  @override
  String toString() =>
      'sandbox($delegate${_rootPath != null ? ', $_rootPath' : ''})';
}
