import 'package:test/test.dart';
import 'package:sqflite_common/sqlite_api.dart';

void main() {
  group('sqlite_api', () {
    // Check that public api are exported
    test('exported', () {
      <dynamic>[
        OpenDatabaseOptions,
        DatabaseFactory,
        Database,
        Transaction,
        Batch,
        ConflictAlgorithm,
        inMemoryDatabasePath,
        OnDatabaseConfigureFn,
        OnDatabaseCreateFn,
        OnDatabaseOpenFn,
        OnDatabaseVersionChangeFn,
        onDatabaseDowngradeDelete,
        sqfliteLogLevelNone,
        sqfliteLogLevelSql,
        sqfliteLogLevelVerbose
      ].forEach((dynamic value) {
        expect(value, isNotNull);
      });
    });
  });
}
