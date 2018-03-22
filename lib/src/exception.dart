import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sqflite/src/constant.dart';

// Wrap sqlite native exception
class DatabaseException implements Exception {
  String _message;
  DatabaseException(this._message);

  @override
  String toString() => "DatabaseException($_message)";

  bool isNoSuchTableError([String table]) {
    if (_message != null) {
      String expected = "no such table: ";
      if (table != null) {
        expected += table;
      }
      return _message.contains(expected);
    }
    return false;
  }

  bool isSyntaxError([String table]) {
    if (_message != null) {
      return _message.contains("syntax error");
    }
    return false;
  }

  bool isOpenFailedError() {
    if (_message != null) {
      return _message.startsWith("open_failed");
    }
    return false;
  }

  bool isDatabaseClosedError() {
    if (_message != null) {
      return _message.startsWith("database_closed");
    }
    return false;
  }

  isReadOnlyError() {
    if (_message != null) {
      return _message.contains("readonly");
    }
    return false;
  }
}

Future<T> wrapDatabaseException<T>(Future<T> action()) async {
  try {
    T result = await action();
    return result;
  } on PlatformException catch (e) {
    if (e.code == sqliteErrorCode) {
      throw new DatabaseException(e.message);
      //rethrow;
    } else {
      rethrow;
    }
  }
}
