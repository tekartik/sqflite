import 'package:flutter/services.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/exception.dart';

Future<T> wrapDatabaseException<T>(Future<T> action()) async {
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
