import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';

/// Callback for iteration. Return `false` to stop.
typedef SqfliteCursorRowCallback =
    FutureOr<bool> Function(Map<String, Object?> row);

/// Iterate extension on [DatabaseExecutor]
extension SqfliteDatabaseExecutorIterateExt on DatabaseExecutor {
  /// Iterate over the results of a raw query.
  ///
  /// [onRow] is called for each row. Return `false` to stop the iteration.
  Future<void> rawQueryIterate(
    String sql,
    List<Object?>? arguments, {
    int? bufferSize,
    required SqfliteCursorRowCallback onRow,
  }) async {
    final cursor = await rawQueryCursor(sql, arguments, bufferSize: bufferSize);
    try {
      while (await cursor.moveNext()) {
        if (!(await onRow(cursor.current))) {
          break;
        }
      }
    } finally {
      await cursor.close();
    }
  }

  /// Iterate over the results of a query.
  ///
  /// [onRow] is called for each row. Return `false` to stop the iteration.
  Future<void> queryIterate(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
    required SqfliteCursorRowCallback onRow,
  }) async {
    final cursor = await queryCursor(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
      bufferSize: bufferSize,
    );
    try {
      while (await cursor.moveNext()) {
        if (!(await onRow(cursor.current))) {
          break;
        }
      }
    } finally {
      await cursor.close();
    }
  }
}
