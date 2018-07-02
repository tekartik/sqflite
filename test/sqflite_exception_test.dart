import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/src/exception.dart';

void main() {
  group("sqflite_exception", () {
    test("isUniqueContraint", () async {
      // Android
      String msg = "UNIQUE constraint failed: Test.name (code 2067))";
      var exception = new SqfliteDatabaseException(msg, null);
      expect(exception.isDatabaseClosedError(), isFalse);
      expect(exception.isReadOnlyError(), isFalse);
      expect(exception.isNoSuchTableError(), isFalse);
      expect(exception.isOpenFailedError(), isFalse);
      expect(exception.isSyntaxError(), isFalse);
      expect(exception.isUniqueConstraintError(), isTrue);
      expect(exception.isUniqueConstraintError("Test.name"), isTrue);

      msg = "UNIQUE constraint failed: Test.name (code 1555))";
      expect(exception.isSyntaxError(), isFalse);
      expect(exception.isUniqueConstraintError(), isTrue);
      expect(exception.isUniqueConstraintError("Test.name"), isTrue);
    });

    test("isSyntaxError", () async {
      // Android
      String msg = 'near "DUMMY": syntax error (code 1)';
      var exception = new SqfliteDatabaseException(msg, null);
      expect(exception.isDatabaseClosedError(), isFalse);
      expect(exception.isReadOnlyError(), isFalse);
      expect(exception.isNoSuchTableError(), isFalse);
      expect(exception.isOpenFailedError(), isFalse);
      expect(exception.isSyntaxError(), isTrue);
      expect(exception.isUniqueConstraintError(), isFalse);
      expect(exception.getResultCode(), 1);
    });

    test("isNoSuchTable", () async {
      // Android
      String msg = "no such table: Test (code 1)";
      var exception = new SqfliteDatabaseException(msg, null);
      expect(exception.isDatabaseClosedError(), isFalse);
      expect(exception.isReadOnlyError(), isFalse);
      expect(exception.isNoSuchTableError(), isTrue);
      expect(exception.isNoSuchTableError("Test"), isTrue);
      expect(exception.isNoSuchTableError("Other"), isFalse);
      expect(exception.isOpenFailedError(), isFalse);
      expect(exception.isSyntaxError(), isFalse);
      expect(exception.isUniqueConstraintError(), isFalse);
      expect(exception.getResultCode(), 1);
    });

    test("getResultCode", () async {
      // Android
      String msg = "UNIQUE constraint failed: Test.name (code 2067))";
      var exception = new SqfliteDatabaseException(msg, null);
      expect(exception.getResultCode(), 2067);
      exception = new SqfliteDatabaseException(
          "UNIQUE constraint failed: Test.name (code 1555))", null);
      expect(exception.getResultCode(), 1555);
      exception = new SqfliteDatabaseException(
          'near "DUMMY": syntax error (code 1)', null);
      expect(exception.getResultCode(), 1);

      exception = new SqfliteDatabaseException(
          'attempt to write a readonly database (code 8)) running Open read-only',
          null);
      expect(exception.getResultCode(), 8);
    });
  });
}
