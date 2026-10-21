import 'package:flutter/services.dart';

import 'sqflite_import.dart';

/// Wrap any exception to a [DatabaseException]
Future<T> wrapDatabaseException<T>(Future<T> Function() action) async {
  try {
    final result = await action();
    return result;
  } on PlatformException catch (e) {
    if (e.code == sqliteErrorCode) {
      final details = e.details;
      throw SqfliteDatabaseException(
        e.message!,
        details,
        // Set when the native side found the transaction rolled back by SQLite
        transactionClosed:
            details is Map && details['transactionClosed'] == true
            ? true
            : null,
      );
      //rethrow;
    } else {
      rethrow;
    }
  }
}
