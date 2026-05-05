import 'package:sqflite_common/src/sql_builder.dart';

/// Sql command type.
enum SqliteSqlCommandType {
  /// such CREATE TABLE, DROP_INDEX, pragma
  execute,

  /// Insert statement,
  insert,

  /// Update statement.
  update,

  /// Delete statement.
  delete,

  /// Query statement (SELECT)
  query,
}

/// Sql command. internal only.
abstract class SqfliteSqlCommand {
  /// The command type.
  SqliteSqlCommandType get type;

  /// The sql statement.
  String get sql;

  /// The sql arguments.
  List<Object?>? get arguments;

  /// Sql command.
  factory SqfliteSqlCommand.raw(
    SqliteSqlCommandType type,
    String sql, [
    List<Object?>? arguments,
  ]) {
    return _SqfliteSqlCommand(type, sql, arguments);
  }

  /// Query command.
  factory SqfliteSqlCommand.rawQuery(String sql, [List<Object?>? arguments]) {
    return _SqfliteSqlCommand(SqliteSqlCommandType.query, sql, arguments);
  }

  /// Insert command.
  factory SqfliteSqlCommand.rawInsert(String sql, [List<Object?>? arguments]) {
    return _SqfliteSqlCommand(SqliteSqlCommandType.insert, sql, arguments);
  }

  /// Update command.
  factory SqfliteSqlCommand.rawUpdate(String sql, [List<Object?>? arguments]) {
    return _SqfliteSqlCommand(SqliteSqlCommandType.update, sql, arguments);
  }

  /// Delete command.
  factory SqfliteSqlCommand.rawDelete(String sql, [List<Object?>? arguments]) {
    return _SqfliteSqlCommand(SqliteSqlCommandType.delete, sql, arguments);
  }

  /// Execute command.
  factory SqfliteSqlCommand.execute(String sql, [List<Object?>? arguments]) {
    return _SqfliteSqlCommand(SqliteSqlCommandType.execute, sql, arguments);
  }

  /// Query factory.
  factory SqfliteSqlCommand.query(
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
  }) {
    final builder = SqlBuilder.query(
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
    );
    return _SqfliteSqlCommand(
      SqliteSqlCommandType.query,
      builder.sql,
      builder.arguments,
    );
  }

  /// Insert factory.
  factory SqfliteSqlCommand.insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    final builder = SqlBuilder.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
    return _SqfliteSqlCommand(
      SqliteSqlCommandType.insert,
      builder.sql,
      builder.arguments,
    );
  }

  /// Update factory.
  factory SqfliteSqlCommand.update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    final builder = SqlBuilder.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
    return _SqfliteSqlCommand(
      SqliteSqlCommandType.update,
      builder.sql,
      builder.arguments,
    );
  }

  /// Delete factory.
  factory SqfliteSqlCommand.delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    final builder = SqlBuilder.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
    return _SqfliteSqlCommand(
      SqliteSqlCommandType.delete,
      builder.sql,
      builder.arguments,
    );
  }
}

/// Private implementation.
class _SqfliteSqlCommand implements SqfliteSqlCommand {
  @override
  final SqliteSqlCommandType type;

  @override
  final String sql;

  @override
  final List<Object?>? arguments;

  _SqfliteSqlCommand(this.type, this.sql, this.arguments);
}
