import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

void main() {
  group('sqlite_api', () {
    // Check that public api are exported
    test('exported', () {
      for (var value in <dynamic>[
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
        sqfliteLogLevelVerbose,
        SqfliteSqlCommand,

        SqfliteCursorRowCallback,
        (null as DatabaseExecutor?)?.rawQueryIterate ?? false,
        (null as DatabaseExecutor?)?.queryIterate ?? false,
        SqfliteSqlCommand.raw(SqliteSqlCommandType.execute, 'PRAGMA'),
        (null as SqfliteSqlCommand?)?.query ?? false,
        SqliteSqlCommandType.query,
      ]) {
        expect(value, isNotNull);
      }
    });
  });
}
