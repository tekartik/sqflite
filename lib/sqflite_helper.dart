// Copyright (C) 2006 The Android Open Source Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'package:sqflite/sqflite.dart';

class SQFliteHelper {

  static SQFliteHelper _singleton;

  factory SQFliteHelper(String path, {int version, OnDatabaseCreateFn onCreate,
    OnDatabaseVersionChangeFn onUpgrade, OnDatabaseVersionChangeFn onDowngrade,
    OnDatabaseOpenFn onOpen}) {
    return _singleton != null ? _singleton :
    _singleton = new SQFliteHelper._internal(path,
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen
    );
  }

  SQFliteHelper._internal(String path,
      {int version, OnDatabaseCreateFn onCreate,
        OnDatabaseVersionChangeFn onUpgrade, OnDatabaseVersionChangeFn onDowngrade,
        OnDatabaseOpenFn onOpen}) {
    openDatabase(path,
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen
    ).then((database) => SQFliteHelper.database = database);
  }

  static Database database;

  Future<List<Map<String, dynamic>>> query(String table, {bool distinct,
    List<String> columns, String selection, List<String> selectionArgs,
    String groupBy, String having, String orderBy, String limit}) {
    return database.query(
        _SQLiteQueryBuilder.buildQueryString(table,
            distinct: distinct,
            columns: columns,
            where: selection,
            groupBy: groupBy,
            having: having,
            orderBy: orderBy,
            limit: limit
        ), selectionArgs);
  }

  Future<int> insertFromMap(String table, { String nullColumnHack,
    Map<String, dynamic> values, int conflictAlgorithm}) {
    return database.insert(
        _SQLiteQueryBuilder.buildInsertString(table,
            nullColumnHack: nullColumnHack,
            initialValues: values,
            conflictAlgorithm: conflictAlgorithm)
    );
  }

  Future<int> insert(String table, { String nullColumnHack,
    Mappable values, int conflictAlgorithm}) {
    return database.insert(
        _SQLiteQueryBuilder.buildInsertString(table,
            nullColumnHack: nullColumnHack,
            initialValues: values.getMap(),
            conflictAlgorithm: conflictAlgorithm)
    );
  }

  Future<int> bulkInsertFromMap(String table, {String nullColumnHack,
    List<Map<String, dynamic>> items, int conflictAlgorithm}) async {
    int i;
    await database.inTransaction(() {
      items.forEach((values) async {
        i += await insertFromMap(table,
            nullColumnHack: nullColumnHack,
            values: values,
            conflictAlgorithm: conflictAlgorithm);
      });
    });

    return i;
  }

  Future<int> bulkInsert(String table, {String nullColumnHack,
    List<Mappable> items, int conflictAlgorithm}) async {
    int i;
    await database.inTransaction(() {
      items.forEach((values) async {
        i += await insert(table,
            nullColumnHack: nullColumnHack,
            values: values,
            conflictAlgorithm: conflictAlgorithm);
      });
    });

    return i;
  }

  Future<int> updateFromMap(String table,
      { Map<String, dynamic> values, String whereClause,
        List<String> whereArgs, int conflictAlgorithm}) {
    return database.update(
        _SQLiteQueryBuilder.buildUpdateString(table,
            values: values,
            whereClause: whereClause,
            whereArgs: whereArgs,
            conflictAlgorithm: conflictAlgorithm
        )
    );
  }

  Future<int> update(String table, { Mappable values, String whereClause,
    List<String> whereArgs, int conflictAlgorithm}) {
    return database.update(
        _SQLiteQueryBuilder.buildUpdateString(table,
            values: values.getMap(),
            whereClause: whereClause,
            whereArgs: whereArgs,
            conflictAlgorithm: conflictAlgorithm
        )
    );
  }

  delete(String table, {String whereClause, List<String> whereArgs}) {
    return database.delete(
        _SQLiteQueryBuilder.buildDeleteString(table,
            whereClause: whereClause,
            whereArgs: whereArgs)
    );
  }

  Database getDatabaseObject() {
    return database;
  }
}

///Implement this interface if you want
abstract class Mappable {
  Map<String, dynamic> getMap();
}

/// When a constraint violation occurs, an immediate ROLLBACK occurs,
/// thus ending the current transaction, and the command aborts with a
/// return code of SQLITE_CONSTRAINT. If no transaction is active
/// (other than the implied transaction that is created on every command)
/// then this algorithm works the same as ABORT.

const int CONFLICT_ROLLBACK = 1;


/// When a constraint violation occurs,no ROLLBACK is executed
/// so changes from prior commands within the same transaction
/// are preserved. This is the default behavior.

const int CONFLICT_ABORT = 2;


/// When a constraint violation occurs, the command aborts with a return
/// code SQLITE_CONSTRAINT. But any changes to the database that
/// the command made prior to encountering the constraint violation
/// are preserved and are not backed out.

const int CONFLICT_FAIL = 3;


/// When a constraint violation occurs, the one row that contains
/// the constraint violation is not inserted or changed.
/// But the command continues executing normally. Other rows before and
/// after the row that contained the constraint violation continue to be
/// inserted or updated normally. No error is returned.

const int CONFLICT_IGNORE = 4;


/// When a UNIQUE constraint violation occurs, the pre-existing rows that
/// are causing the constraint violation are removed prior to inserting
/// or updating the current row. Thus the insert or update always occurs.
/// The command continues executing normally. No error is returned.
/// If a NOT NULL constraint violation occurs, the NULL value is replaced
/// by the default value for that column. If the column has no default
/// value, then the ABORT algorithm is used. If a CHECK constraint
/// violation occurs then the IGNORE algorithm is used. When this conflict
/// resolution strategy deletes rows in order to satisfy a constraint,
/// it does not invoke delete triggers on those rows.
/// This behavior might change in a future release.

const int CONFLICT_REPLACE = 5;


/// Use the following when no conflict action is specified.

const int CONFLICT_NONE = 0;

class _SQLiteQueryBuilder {

  static final List<String> _conflictValues = [
    "",
    " OR ROLLBACK ",
    " OR ABORT ",
    " OR FAIL ",
    " OR IGNORE ",
    " OR REPLACE "
  ];

  static final RegExp sLimitPattern = new RegExp("\s*\d+\s*(,\s*\d+\s*)?");

  /// Build an SQL query string from the given clauses.
  ///
  /// @param distinct true if you want each row to be unique, false otherwise.
  /// @param table The table names to compile the query against.
  /// @param columns A list of which columns to return. Passing null will
  ///            return all columns, which is discouraged to prevent reading
  ///            data from storage that isn't going to be used.
  /// @param where A filter declaring which rows to return, formatted as an SQL
  ///            WHERE clause (excluding the WHERE itself). Passing null will
  ///            return all rows for the given URL.
  /// @param groupBy A filter declaring how to group rows, formatted as an SQL
  ///            GROUP BY clause (excluding the GROUP BY itself). Passing null
  ///            will cause the rows to not be grouped.
  /// @param having A filter declare which row groups to include in the cursor,
  ///            if row grouping is being used, formatted as an SQL HAVING
  ///            clause (excluding the HAVING itself). Passing null will cause
  ///            all row groups to be included, and is required when row
  ///            grouping is not being used.
  /// @param orderBy How to order the rows, formatted as an SQL ORDER BY clause
  ///            (excluding the ORDER BY itself). Passing null will use the
  ///            default sort order, which may be unordered.
  /// @param limit Limits the number of rows returned by the query,
  ///            formatted as LIMIT clause. Passing null denotes no LIMIT clause.
  /// @return the SQL query string

  static String buildQueryString(String table, {bool distinct = false,
    List<String> columns, String where = "", String groupBy = "",
    String having = "", String orderBy = "", String limit = ""}) {
    if (groupBy != null && having != null &&
        groupBy.isEmpty && having.isNotEmpty) {
      throw new ArgumentError(
          "HAVING clauses are only permitted when using a groupBy clause");
    }


    if (limit != null && limit.isNotEmpty &&
        sLimitPattern
            .allMatches(limit)
            .isNotEmpty) {
      throw new ArgumentError("invalid LIMIT clauses: $limit");
    }

    StringBuffer query = new StringBuffer();

    query.write("SELECT ");
    if (distinct) {
      query.write("DISTINCT ");
    }
    if (columns != null && columns.length != 0) {
      _writeColumns(query, columns);
    } else {
      query.write("* ");
    }
    query.write("FROM ");
    query.write(table);
    _writeClause(query, " WHERE ", where);
    _writeClause(query, " GROUP BY ", groupBy);
    _writeClause(query, " HAVING ", having);
    _writeClause(query, " ORDER BY ", orderBy);
    _writeClause(query, " LIMIT ", limit);

    return query.toString();
  }


  static String buildInsertString(String table, {String nullColumnHack,
    Map<String,
        dynamic> initialValues, int conflictAlgorithm = CONFLICT_NONE}) {
    StringBuffer sql = new StringBuffer();
    sql.write("INSERT");
    sql.write(_conflictValues[conflictAlgorithm]);
    sql.write(" INTO ");
    sql.write(table);
    sql.write('(');

    List bindArgs;
    int size = (initialValues != null && initialValues.length > 0)
        ? initialValues.length : 0;
    if (size > 0) {
      bindArgs = new List(size);
      int i = 0;
      initialValues.keys.forEach((colName) {
        sql.write((i > 0) ? "," : "");
        sql.write(colName);
        bindArgs[i++] = initialValues[colName];
      });

      sql.write(')');
      sql.write(" VALUES (");
      for (i = 0; i < size; i++) {
        sql.write((i > 0) ? ",?" : "?");
      }
    } else {
      sql.write(nullColumnHack + ") VALUES (NULL");
    }
    sql.write(')');

    return sql.toString();
  }


  /// Convenience method for updating rows in the database.
  ///
  /// @param table the table to update in
  /// @param values a map from column names to new column values. null is a
  ///            valid value that will be translated to NULL.
  /// @param whereClause the optional WHERE clause to apply when updating.
  ///            Passing null will update all rows.
  /// @param whereArgs You may include ?s in the where clause, which
  ///            will be replaced by the values from whereArgs. The values
  ///            will be bound as Strings.
  /// @param conflictAlgorithm for update conflict resolver
  /// @return the number of rows affected

  static String buildUpdateString(String table,
      { Map<String, dynamic> values, String whereClause = "",
        List<String> whereArgs, int conflictAlgorithm = CONFLICT_NONE}) {
    if (values == null || values.isEmpty) {
      throw new ArgumentError("Empty values");
    }

    StringBuffer sql = new StringBuffer();
    sql.write("UPDATE ");
    sql.write(_conflictValues[conflictAlgorithm]);
    sql.write(table);
    sql.write(" SET ");


    int setValuesSize = values.length;
    int bindArgsSize = (whereArgs == null) ? setValuesSize : (setValuesSize +
        whereArgs.length);

    List bindArgs = new List(bindArgsSize);
    int i = 0;

    values.keys.forEach((colName) {
      sql.write((i > 0) ? "," : "");
      sql.write(colName);
      bindArgs[i++] = values [colName];
      sql.write("=?");
    });

    if (whereArgs != null) {
      for (i = setValuesSize; i < bindArgsSize; i++) {
        bindArgs[i] = whereArgs[i - setValuesSize];
      }
    }

    if (whereClause.isNotEmpty) {
      sql.write(" WHERE ");
      sql.write(whereClause);
    }

    return sql.toString();
  }


  /// Convenience method for deleting rows in the database.
  ///
  /// @param table the table to delete from
  /// @param whereClause the optional WHERE clause to apply when deleting.
  ///            Passing null will delete all rows.
  /// @param whereArgs You may include ?s in the where clause, which
  ///            will be replaced by the values from whereArgs. The values
  ///            will be bound as Strings.
  /// @return the number of rows affected if a whereClause is passed in, 0
  ///         otherwise. To remove all rows and get a count pass "1" as the
  ///         whereClause.

  static String buildDeleteString(String table,
      {String whereClause, List<String> whereArgs}) {
    StringBuffer sql = new StringBuffer();
    sql.write("DELETE FROM ");
    sql.write(table);
    sql.write(whereClause.isNotEmpty ? " WHERE " + whereClause : "");

    return sql.toString();
  }


  static void _writeClause(StringBuffer s, String name, String clause) {
    if (clause.isNotEmpty) {
      s.write(name);
      s.write(clause);
    }
  }

  /// Add the names that are non-null in columns to s, separating
  /// them with commas.
  static void _writeColumns(StringBuffer s, List<String> columns) {
    int n = columns.length;

    for (int i = 0; i < n; i++) {
      String column = columns[i];

      if (column != null) {
        if (i > 0) {
          s.write(", ");
        }
        s.write(column);
      }
    }
    s.write(' ');
  }
}