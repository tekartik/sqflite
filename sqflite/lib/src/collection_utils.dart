import 'dart:collection';

import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/constant.dart' as constant;
import 'package:sqflite/src/exception.dart';

export 'dart:async';

/// Native result wrapper
class Rows extends PluginList<Map<String, dynamic>> {
  /// Wrap the native list as a raw
  Rows.from(List<dynamic> list) : super.from(list);

  @override
  Map<String, dynamic> operator [](int index) {
    final Map<dynamic, dynamic> item = rawList[index] as Map<dynamic, dynamic>;
    return item.cast<String, dynamic>();
  }
}

/// Unpack the native results
QueryResultSet queryResultSetFromMap(Map<dynamic, dynamic> queryResultSetMap) {
  final List<dynamic> columns = queryResultSetMap['columns'] as List<dynamic>;
  final List<dynamic> rows = queryResultSetMap['rows'] as List<dynamic>;
  return QueryResultSet(columns, rows);
}

/// Native exception wrapper
DatabaseException databaseExceptionFromOperationError(
    Map<dynamic, dynamic> errorMap) {
  final String message = errorMap[paramErrorMessage] as String;
  return SqfliteDatabaseException(message, errorMap[paramErrorData]);
}

/// A batch operation result is either
/// {'result':...}
/// or
/// {'error':...}
dynamic fromRawOperationResult(Map<dynamic, dynamic> rawOperationResultMap) {
  final Map<dynamic, dynamic> errorMap =
      rawOperationResultMap[constant.paramError] as Map<dynamic, dynamic>;
  if (errorMap != null) {
    return databaseExceptionFromOperationError(errorMap);
  }
  final dynamic successResult = rawOperationResultMap[constant.paramResult];
  if (successResult is Map) {
    return queryResultToList(successResult);
  } else if (successResult is List) {
    return queryResultToList(successResult);
  }

  // This could be just an int (insert)
  return successResult;
}

/// Native result to a map list as expected by the sqflite API
List<Map<String, dynamic>> queryResultToList(dynamic queryResult) {
  // New 0.7.1 format
  // devPrint('queryResultToList: $queryResult');
  if (queryResult == null) {
    return null;
  }
  if (queryResult is Map) {
    return queryResultSetFromMap(queryResult);
  }
  // dart1
  // dart2 support <= 0.7.0 - this is a list
  // to remove once done on iOS and Android
  if (queryResult is List) {
    final Rows rows = Rows.from(queryResult);
    return rows;
  }

  throw 'Unsupported queryResult type $queryResult';
}

/// Query native result
class QueryResultSet extends ListBase<Map<String, dynamic>> {
  /// Creates a result set from a native column/row values
  QueryResultSet(List<dynamic> rawColumns, List<dynamic> rawRows) {
    _columns = rawColumns?.cast<String>();
    _rows = rawRows?.cast<List<dynamic>>();
    if (_columns != null) {
      _columnIndexMap = <String, int>{};

      for (int i = 0; i < _columns.length; i++) {
        _columnIndexMap[_columns[i]] = i;
      }
    }
  }

  List<List<dynamic>> _rows;
  List<String> _columns;
  List<String> _keys;
  Map<String, int> _columnIndexMap;

  @override
  int get length => _rows?.length ?? 0;

  @override
  Map<String, dynamic> operator [](int index) {
    return QueryRow(this, _rows[index]);
  }

  @override
  void operator []=(int index, Map<String, dynamic> value) {
    throw UnsupportedError('read-only');
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('read-only');
  }

  /// Get the column index for a give column name
  int columnIndex(String name) {
    return _columnIndexMap[name];
  }

  /// Remove duplicated
  List<String> get keys => _keys ??= _columns.toSet().toList(growable: false);
}

/// Query Row wrapper
class QueryRow extends MapBase<String, dynamic> {
  /// Create a row from a result set information and a list of values
  QueryRow(this.queryResultSet, this.row);

  /// Our result set
  final QueryResultSet queryResultSet;

  /// Our row values
  final List<dynamic> row;

  @override
  dynamic operator [](Object key) {
    final String stringKey = key as String;
    final int columnIndex = queryResultSet.columnIndex(stringKey);
    if (columnIndex != null) {
      return row[columnIndex];
    }
    return null;
  }

  @override
  void operator []=(String key, dynamic value) {
    throw UnsupportedError('read-only');
  }

  @override
  void clear() {
    throw UnsupportedError('read-only');
  }

  @override
  Iterable<String> get keys => queryResultSet.keys;

  @override
  dynamic remove(Object key) {
    throw UnsupportedError('read-only');
  }
}

/// Single batch operation results.
class BatchResult {
  /// Wrap a batch  operation result.
  BatchResult(this.result);

  /// Our operation result
  final dynamic result;
}

/// Batch results.
class BatchResults extends PluginList<dynamic> {
  /// Creates a batch result from a native list.
  BatchResults.from(List<dynamic> list) : super.from(list);

  @override
  dynamic operator [](int index) {
    // New in 0.13
    // It is always a Map and can be either a result or an error
    final Map<dynamic, dynamic> rawMap = _list[index] as Map<dynamic, dynamic>;
    return fromRawOperationResult(rawMap);
  }
}

/// Helper to handle a native list.
abstract class PluginList<T> extends ListBase<T> {
  /// Creates a types list from a native list.
  PluginList.from(List<dynamic> list) : _list = list;

  final List<dynamic> _list;

  /// Our raw native list.
  List<dynamic> get rawList => _list;

  /// Get a raw element.
  dynamic rawElementAt(int index) => _list[index];

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    throw UnsupportedError('read-only');
  }

  @override
  void operator []=(int index, T value) {
    throw UnsupportedError('read-only');
  }
}
