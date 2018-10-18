import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:flutter/services.dart';
import 'package:sqflite/src/utils.dart';

import 'package:sqflite/src/constant.dart' as constant;

const String channelName = 'com.tekartik.sqflite';

Duration lockWarningDuration = constant.lockWarningDuration;
void Function() lockWarningCallback = () {
  print('Warning database has been locked for $lockWarningDuration. '
      'Make sure you always use the transaction object for database operations during a transaction');
};

const MethodChannel channel = MethodChannel(channelName);

// Temp flag to test concurrent reads
final bool supportsConcurrency = false;

// Make it async safe for dart 2.0.0-dev28+ preview dart 2
Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
  final T result = await channel.invokeMethod(method, arguments);
  return result;
}

// Starting Dart preview 2, wrap the result
class Rows extends PluginList<Map<String, dynamic>> {
  Rows.from(List<dynamic> list) : super.from(list);

  @override
  Map<String, dynamic> operator [](int index) {
    final Map<dynamic, dynamic> item = rawList[index];
    return item.cast<String, dynamic>();
  }
}

Map<String, dynamic> newQueryResultSetMap(
    List<String> columns, List<List<dynamic>> rows) {
  final Map<String, dynamic> map = <String, dynamic>{
    "columns": columns,
    "rows": rows
  };
  return map;
}

QueryResultSet queryResultSetFromMap(Map<dynamic, dynamic> queryResultSetMap) {
  final List<dynamic> columns = queryResultSetMap["columns"];
  final List<dynamic> rows = queryResultSetMap["rows"];
  return QueryResultSet(columns, rows);
}

List<Map<String, dynamic>> queryResultToList(dynamic queryResult) {
  // New 0.7.1 format
  // devPrint("queryResultToList: $queryResult");
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

class QueryResultSet extends ListBase<Map<String, dynamic>> {
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
  Map<String, int> _columnIndexMap;

  @override
  int get length => _rows?.length ?? 0;

  @override
  Map<String, dynamic> operator [](int index) {
    return QueryRow(this, _rows[index]);
  }

  @override
  void operator []=(int index, Map<String, dynamic> value) {
    throw UnsupportedError("read-only");
  }

  @override
  set length(int newLength) {
    throw UnsupportedError("read-only");
  }

  int columnIndex(String name) {
    return _columnIndexMap[name];
  }
}

class QueryRow extends MapBase<String, dynamic> {
  QueryRow(this.queryResultSet, this.row);

  final QueryResultSet queryResultSet;
  final List<dynamic> row;

  @override
  dynamic operator [](Object key) {
    final String stringKey = key;
    final int columnIndex = queryResultSet.columnIndex(stringKey);
    if (columnIndex != null) {
      return row[columnIndex];
    }
    return null;
  }

  @override
  void operator []=(String key, dynamic value) {
    throw UnsupportedError("read-only");
  }

  @override
  void clear() {
    throw UnsupportedError("read-only");
  }

  @override
  Iterable<String> get keys => queryResultSet._columns;

  @override
  dynamic remove(Object key) {
    throw UnsupportedError("read-only");
  }
}

class BatchResult {
  BatchResult(this.result);
  final dynamic result;
}

class BatchResults extends PluginList<dynamic> {
  BatchResults.from(List<dynamic> list) : super.from(list);

  @override
  dynamic operator [](int index) {
    final dynamic result = _list[index];

    // list or map, this is a result
    if (result is Map) {
      return queryResultToList(result);
    } else if (result is List) {
      return queryResultToList(result);
    }

    return result;
  }
}

abstract class PluginList<T> extends ListBase<T> {
  PluginList.from(List<dynamic> list) : _list = list;

  final List<dynamic> _list;

  List<dynamic> get rawList => _list;

  dynamic rawElementAt(int index) => _list[index];

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    throw UnsupportedError("read-only");
  }

  @override
  void operator []=(int index, T value) {
    throw UnsupportedError("read-only");
  }
}

void setLockWarningInfo({Duration duration, void callback()}) {
  lockWarningDuration = duration ?? lockWarningDuration;
  lockWarningCallback = callback ?? lockWarningCallback;
}

/// Utility to encode a blob to allow blow query using
/// "hex(blob_field) = ?", Sqlite.hex([1,2,3])
String hex(List<int> bytes) {
  final StringBuffer buffer = StringBuffer();
  for (int part in bytes) {
    if (part & 0xff != part) {
      throw FormatException("$part is not a byte integer");
    }
    buffer.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return buffer.toString().toUpperCase();
}
