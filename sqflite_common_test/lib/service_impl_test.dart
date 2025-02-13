import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/mixin/import_mixin.dart'; // ignore: implementation_imports
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

import 'src/sqflite_import.dart';

/// Service delegating storing invocations.
class FactoryServiceDelegate with SqfliteDatabaseFactoryMixin {
  /// Factory delegate storing logs
  FactoryServiceDelegate({required DatabaseFactory factory})
    : _factory = factory as SqfliteDatabaseFactory;

  final _ins = <dynamic>[];
  final _outs = <dynamic>[];

  /// List of invoke calls (m: method, a: arguments)
  List<dynamic> get ins => _ins;

  /// Results of invocation, error as `{ e: '<error>' }`
  List<dynamic> get outs => _outs;
  final SqfliteDatabaseFactory _factory;

  /// The base factory
  SqfliteDatabaseFactory get factory => _factory;

  @override
  Future<T> invokeMethod<T>(String method, [arguments]) async {
    var map = <String, Object?>{
      'm': method,
      if (arguments != null) 'a': arguments,
    };
    _ins.add(map);
    T result;
    try {
      result = await _factory.invokeMethod<T>(method, arguments);
    } catch (e) {
      _outs.add(<String, Object?>{'error': e.toString()});
      rethrow;
    }
    _outs.add(result);

    return result;
  }

  /// Clear invocations
  void clear() {
    _ins.clear();
    _outs.clear();
  }
}

/// Run log test
void run(SqfliteTestContext context) {
  var factory = FactoryServiceDelegate(factory: context.databaseFactory);

  int? getId(dynamic item) {
    if (item is Map) {
      return item['id'] as int?;
    }
    return null;
  }

  group('service', () {
    test('open single instance in memory', () async {
      factory.clear();

      var db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await db.close();

      var ins = factory.ins;
      var outs = factory.outs;
      // The 2 printf we always want
      print('ins $ins');
      print('outs $outs');

      var id = getId(outs[0]);

      expect(factory.ins, [
        {
          'm': 'openDatabase',
          'a': {'path': ':memory:', 'singleInstance': false},
        },
        {
          'm': 'closeDatabase',
          'a': {'id': id},
        },
      ]);
      expect(outs, [
        {'id': id},
        null,
      ]);
    });
  });
}
