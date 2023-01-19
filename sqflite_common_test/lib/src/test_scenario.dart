// ignore_for_file: public_member_api_docs

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_test/src/sqflite_import.dart';
import 'package:test/test.dart';

/// Mock method call.
class MockMethodCall {
  /// Expected method call.
  String? expectedMethod;

  /// Expected method call.
  dynamic expectedArguments;

  /// Sent response (can be an exception) or expected response when using
  /// a real factory.
  dynamic response;

  @override
  String toString() => '$expectedMethod $expectedArguments $response';
}

/// Mock scenario.
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
  late List<MockMethodCall> methodsCalls;
  var index = 0;
  dynamic exception;

  void end() {
    expect(exception, isNull, reason: '$exception');
    expect(index, methodsCalls.length);
  }
}

DatabaseFactory createMockFactoryFromData(List<List> data) {
  return _startScenario(data).factory;
}

/// For each row:
/// - First item is the method,
/// - 2nd is the argument
/// - 3rd is the response (expected or set by mock)
MockScenario _startScenario(List<List> data) {
  late MockScenario scenario;
  final databaseFactoryMock = buildDatabaseFactory(
      tag: 'mock',
      invokeMethod: (String method, [Object? arguments]) async {
        final index = scenario.index++;
        // devPrint('$index ${scenario.methodsCalls[index]}');
        final item = scenario.methodsCalls[index];
        try {
          expect(method, item.expectedMethod);
          expect(arguments, item.expectedArguments);
        } catch (e) {
          // devPrint(e);
          scenario.exception ??= '$e $index';
        }
        if (item.response is DatabaseException) {
          throw item.response as DatabaseException;
        }
        return item.response;
      });
  scenario = MockScenario(databaseFactoryMock, data);
  return scenario;
}

/// Either wrap calls to an original factory, either use an implementation.
MockScenario wrapStartScenario(DatabaseFactory? factory, List<List> data) {
  if (factory == null) {
    return _startScenario(data);
  }
  var databaseIdFixed = 0;
  late MockScenario scenario;
  final databaseFactoryMock = buildDatabaseFactory(
      tag: 'mock',
      invokeMethod: (String method, [Object? arguments]) async {
        final index = scenario.index++;
        // devPrint('$index ${scenario.methodsCalls[index]}');
        final item = scenario.methodsCalls[index];
        try {
          expect(method, item.expectedMethod);
          expect(arguments, item.expectedArguments);
        } catch (e) {
          // devPrint(e);
          scenario.exception ??= '$e $index';
        }

        Object? response;
        Object? invokeException;
        try {
          if (method != methodOpenDatabase) {
            // Modify the database id to work for 1
            if (arguments is Map && arguments[paramId] == 1) {
              arguments[paramId] = databaseIdFixed;
            }
          }
          // ignore: invalid_use_of_visible_for_testing_member
          response = await factory.internalsInvokeMethod(method, arguments);

          if (method == methodOpenDatabase) {
            var map = response as Map;
            // Save the database id and tweak the return value
            databaseIdFixed = map[paramId] as int;
            map[paramId] = 1;
          }
        } catch (e) {
          invokeException = e;
          scenario.exception ??= '$e $index';
        }
        if (invokeException != null) {
          if (item.response is DatabaseException) {
            // ok
          } else {
            scenario.exception ??= '$invokeException $index';
          }
          throw invokeException;
        } else {
          try {
            expect(response, item.response);
          } catch (e) {
            // devPrint(e);
            scenario.exception ??= '$e $index';
          }
        }
        return response;
      });
  scenario = MockScenario(databaseFactoryMock, data);
  return scenario;
}
