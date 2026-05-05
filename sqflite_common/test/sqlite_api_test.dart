import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/sql_command.dart';
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
        (null as DatabaseExecutor?)?.rawQueryIterate,
        (null as DatabaseExecutor?)?.queryIterate,
        SqfliteSqlCommand.raw(SqliteSqlCommandType.execute, 'PRAGMA'),
        (null as SqfliteSqlCommand?)?.query,
      ]) {
        expect(value, isNotNull);
      }
    });
  });
}
