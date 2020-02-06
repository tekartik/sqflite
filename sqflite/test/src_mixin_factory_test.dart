import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/mixin/factory.dart';

void main() {
  group('mixin_factory', () {
    test('public', () {
      // ignore: unnecessary_statements
      buildDatabaseFactory;
      // ignore: unnecessary_statements
      SqfliteInvokeHandler;
    });
    test('buildDatabaseFactory', () async {
      final List<String> methods = <String>[];
      final DatabaseFactory factory = buildDatabaseFactory(
          invokeMethod: (String method, [dynamic arguments]) async {
        dynamic result;
        methods.add(method);
        return result;
      });
      expect(factory is SqfliteInvokeHandler, isTrue);
      await factory.openDatabase(inMemoryDatabasePath);
      expect(methods, <String>['openDatabase']);
    });
  });
}
