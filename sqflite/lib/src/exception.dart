import 'package:sqflite/src/constant.dart';

/// Wrap sqlite native exception
abstract class DatabaseException implements Exception {
  /// Create an exception with a message
  DatabaseException(this._message);

  final String _message;

  @override
  String toString() => 'DatabaseException($_message)';

  /// True if the exception is a no such table exception
  bool isNoSuchTableError([String table]) {
    if (_message != null) {
      String expected = 'no such table: ';
      if (table != null) {
        expected += table;
      }
      return _message.contains(expected);
    }
    return false;
  }

  /// True if the exception is a syntax error
  bool isSyntaxError() {
    if (_message != null) {
      return _message.contains('syntax error');
    }
    return false;
  }

  /// True if the exception is an open failed error
  bool isOpenFailedError() {
    if (_message != null) {
      return _message.contains('open_failed');
    }
    return false;
  }

  /// True if the exception is a database closed error
  bool isDatabaseClosedError() {
    if (_message != null) {
      return _message.contains('database_closed');
    }
    return false;
  }

  /// True if the exception is a read-only error
  bool isReadOnlyError() {
    if (_message != null) {
      return _message.contains('readonly');
    }
    return false;
  }

  /// True if the exception is a unique constraint error
  bool isUniqueConstraintError([String field]) {
    if (_message != null) {
      String expected = 'UNIQUE constraint failed: ';
      if (field != null) {
        expected += field;
      }
      return _message.toLowerCase().contains(expected.toLowerCase());
    }
    return false;
  }
}

/// Exception implementation
class SqfliteDatabaseException extends DatabaseException {
  /// ctor with a message and some data
  SqfliteDatabaseException(String message, this.result) : super(message);

  /// Our exception message
  String get message => _message;

  /// Typically the result of a native call
  dynamic result;

  @override
  String toString() {
    if (result is Map) {
      if (result[paramSql] != null) {
        final dynamic args = result[paramSqlArguments];
        if (args == null) {
          return "DatabaseException($_message) sql '${result[paramSql]}'";
        } else {
          return "DatabaseException($_message) sql '${result[paramSql]}' args $args}";
        }
      }
    }
    return super.toString();
  }

  /// Parse the sqlite native message to extract the code
  /// See https://www.sqlite.org/rescode.html for the list of result code
  int getResultCode() {
    final String message = _message.toLowerCase();
    int findCode(String patternPrefix) {
      final int index = message.indexOf(patternPrefix);
      if (index != -1) {
        final String code = message.substring(index + patternPrefix.length);
        final int endIndex = code.indexOf(')');
        if (endIndex != -1) {
          try {
            final int resultCode = int.parse(code.substring(0, endIndex));
            if (resultCode != null) {
              return resultCode;
            }
          } catch (_) {}
        }
      }
      return null;
    }

    int code = findCode('(sqlite code ');
    if (code != null) {
      return code;
    }
    code = findCode('(code ');
    if (code != null) {
      return code;
    }
    return null;
  }
}
