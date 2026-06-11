import 'package:meta/meta.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'import.dart';

/// The Ffi async database factory interface
abstract class SqfliteDatabaseFactoryFfiAsync implements DatabaseFactory {}

/// The Ffi async database factory implementation mixin.
mixin SqfliteDatabaseFactoryFfiAsyncMixin
    implements SqfliteDatabaseFactoryFfiAsync, SqfliteDatabaseFactoryMixin {
  /// Allow overriding, use regular ffi otherwise
  String? _databasesPath;

  /// Ffi based implementation to override
  @protected
  Future<String?> ffiAsyncGetDatabasesPathOrNull() async {
    return _databasesPath;
  }

  @override
  Future<T> wrapDatabaseException<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw ffiWrapAnyException(e);
    }
  }

  /// Set the databases path.
  @override
  void setDatabasesPathOrNull(String? path) {
    _databasesPath = path;
  }

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) async {
    switch (method) {
      case methodOptions:
        return null as T;
    }
    throw UnimplementedError('Unimplemented method $method');
  }
}
