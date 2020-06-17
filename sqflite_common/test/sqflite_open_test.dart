import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/mixin/factory.dart';
import 'package:test/test.dart';

class MockMethodCall {
  String expectedMethod;
  dynamic expectedArguments;
  dynamic response;

  @override
  String toString() => '$expectedMethod $expectedArguments $response';
}

class MockScenario {
  MockScenario(this.factory, List<List> data) {
    methodsCalls = data
        .map((list) => MockMethodCall()
          ..expectedMethod = list[0]?.toString()
          ..expectedArguments = list[1]
          ..response = list[2])
        .toList(growable: false);
  }

  final DatabaseFactory factory;
  List<MockMethodCall> methodsCalls;
  var index = 0;
  dynamic exception;

  void end() {
    expect(exception, isNull, reason: '$exception');
    expect(index, methodsCalls.length);
  }
}

MockScenario startScenario(List<List> data) {
  MockScenario scenario;
  final databaseFactoryMock = buildDatabaseFactory(
      invokeMethod: (String method, [dynamic arguments]) async {
    final index = scenario.index++;
    // devPrint('$index ${scenario.methodsCalls[index]}');
    final item = scenario.methodsCalls[index];
    try {
      expect(method, item.expectedMethod);
      expect(arguments, item.expectedArguments);
    } catch (e) {
      scenario.exception ??= '$e $index';
    }
    return item.response;
  });
  scenario = MockScenario(databaseFactoryMock, data);
  return scenario;
}

void main() {
  group('sqflite', () {
    test('open', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true},
          1
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);
      await db.close();
      scenario.end();
    });
    test('open with version', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true},
          1
        ],
        [
          'query',
          {'sql': 'PRAGMA user_version', 'arguments': null, 'id': 1},
          null
        ],
        [
          'execute',
          {
            'sql': 'BEGIN EXCLUSIVE',
            'arguments': null,
            'id': 1,
            'inTransaction': true
          },
          null
        ],
        [
          'query',
          {'sql': 'PRAGMA user_version', 'arguments': null, 'id': 1},
          null
        ],
        [
          'execute',
          {'sql': 'PRAGMA user_version = 1', 'arguments': null, 'id': 1},
          null
        ],
        [
          'execute',
          {'sql': 'COMMIT', 'arguments': null, 'id': 1, 'inTransaction': false},
          null
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(version: 1, onCreate: (db, version) {}));
      await db.close();
      scenario.end();
    });
  });
}
