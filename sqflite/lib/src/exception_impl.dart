import 'package:sqflite/src/services_impl.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/exception.dart';

/// Wrap any exception to a [DatabastException]
Future<T> wrapDatabaseException<T>(Future<T> Function() action) async {
  try {
    final T result = await action();
    return result;
  } on PlatformException catch (e) {
    if (e.code == sqliteErrorCode) {
      throw SqfliteDatabaseException(e.message, e.details);
      //rethrow;
    } else {
      rethrow;
    }
  }
}
