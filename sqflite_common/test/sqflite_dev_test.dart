import 'package:sqflite_common/sqflite_dev.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/method_call.dart';
import 'package:sqflite_common/src/mixin/factory.dart';
import 'package:test/test.dart';

var logs = <SqfliteMethodCall>[];
var databaseFactoryMock =
    buildDatabaseFactory(invokeMethod: (method, [arguments]) async {
  logs.add(SqfliteMethodCall(method, arguments));
});
void main() {
  test('simple sqflite example', () async {
    logs.clear();
    // ignore: deprecated_member_use_from_same_package
    await databaseFactoryMock.setLogLevel(sqfliteLogLevelVerbose);
    expect(logs.map((log) => log.toMap()), [
      {
        'method': 'options',
        'arguments': {'logLevel': 2}
      }
    ]);
  });
  test('databasesPath', () async {
    await databaseFactoryMock.setDatabasesPath('.');
    final path = await databaseFactoryMock.getDatabasesPath();
    expect(path, '.');
    await databaseFactoryMock.setDatabasesPath(null);
  });
}
