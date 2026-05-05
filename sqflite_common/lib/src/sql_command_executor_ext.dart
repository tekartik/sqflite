import 'package:sqflite_common/sqlite_api.dart';

/// Extension on [SqfliteSqlCommand] to execute on a [DatabaseExecutor].
extension SqfliteSqlCommandExecutorExt on SqfliteSqlCommand {
  /// Execute the command as a query.
  Future<List<Map<String, Object?>>> query(DatabaseExecutor executor) {
    return executor.rawQuery(sql, arguments);
  }

  /// Execute the command as an iterative query.
  Future<void> iterate(
    DatabaseExecutor executor, {
    int? bufferSize,
    required SqfliteCursorRowCallback onRow,
  }) {
    return queryIterate(executor, bufferSize: bufferSize, onRow: onRow);
  }

  /// Execute the command as an iterative query.
  Future<void> queryIterate(
    DatabaseExecutor executor, {
    int? bufferSize,
    required SqfliteCursorRowCallback onRow,
  }) {
    return executor.rawQueryIterate(
      sql,
      arguments,
      bufferSize: bufferSize,
      onRow: onRow,
    );
  }

  /// Execute the command as an insert.
  Future<int> insert(DatabaseExecutor executor) {
    return executor.rawInsert(sql, arguments);
  }

  /// Execute the command as an update.
  Future<int> update(DatabaseExecutor executor) {
    return executor.rawUpdate(sql, arguments);
  }

  /// Execute the command as a delete.
  Future<int> delete(DatabaseExecutor executor) {
    return executor.rawDelete(sql, arguments);
  }

  /// Execute the command.
  Future<void> execute(DatabaseExecutor executor) {
    return executor.execute(sql, arguments);
  }
}
