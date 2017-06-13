import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sqflite/src/constant.dart';

// Wrap sqlite native exception
class DatabaseException implements Exception {
  String msg;
  DatabaseException(this.msg);

  @override
  String toString() => "DatabaseException($msg)";

  bool isNoSuchTableError([String table]) {
    if (msg != null) {
      String expected = "no such table: ";
      if (table != null) {
        expected += table;
      }
      return msg.contains(expected);
    }
    return false;
  }

  bool isSyntaxError([String table]) {
    if (msg != null) {
      return msg.contains("syntax error");
    }
    return false;
  }

  bool isOpenFailedError() {
    if (msg != null) {
      return msg.startsWith("open_failed");
    }
    return false;
  }

  bool isDatabaseClosedError() {
    if (msg != null) {
      return msg.startsWith("database_closed");
    }
    return false;
  }
}

Future wrapDatabaseException(action()) async {
  try {
    var result = await action();
    return result;
  } on PlatformException catch (e) {
    //devPrint("C3 ${e.code} $e");
    if (e.code == sqliteErrorCode) {
      //devPrint("D4");
      throw new DatabaseException(e.message);
    } else {
      rethrow;
    }
  }
}