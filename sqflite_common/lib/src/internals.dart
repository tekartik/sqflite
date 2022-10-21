import 'package:meta/meta.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/factory.dart';

/// Internal access to invoke method
extension DatabaseFactoryInternalsExt on DatabaseFactory {
  /// Call invoke method manually.
  @visibleForTesting
  Future<T> internalsInvokeMethod<T>(String method, Object? arguments) async {
    return (this as SqfliteDatabaseFactory).invokeMethod<T>(method, arguments);
  }
}
