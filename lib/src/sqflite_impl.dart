import 'dart:async';
import 'dart:collection';

import 'package:flutter/src/services/platform_channel.dart';
import 'package:sqflite/src/utils.dart';

const String channelName = 'com.tekartik.sqflite';

const MethodChannel channel = const MethodChannel(channelName);

// Temp flag to test concurrent reads
final bool supportsConcurrency = false;

// Make it async safe for dart 2.0.0-dev28+ preview dart 2
Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
  var result = await channel.invokeMethod(method, arguments);
  return result;
}

class PluginIterator<T> implements Iterator<T> {
  final List<T> list;
  PluginIterator(this.list);
  int _currentIndex;

  @override
  bool moveNext() {
    if (_currentIndex == null) {
      if (list.length == 0) {
        return false;
      }
      _currentIndex = 0;
      return true;
    } else {
      return (++_currentIndex < list.length - 1);
    }
  }

  @override
  T get current => list[_currentIndex];
}

class RowIterator extends PluginIterator<Map<String, dynamic>> {
  RowIterator(List<Map<String, dynamic>> list) : super(list);
}

// Starting Dart preview 2, wrap the result
class Rows extends PluginList<Map<String, dynamic>> {
  Rows.from(List list) : super.from(list);
  /*new List.generate(list.length, (index) {
    devPrint("######");
    return new Row.from(list[index]);
  });
  */

  @override
  Map<String, dynamic> operator [](int index) {
    return new Row.from(_list[index]);
  }
}

class BatchResult {
  final result;
  BatchResult(this.result);
}

class BatchResults extends PluginList<dynamic> {
  BatchResults.from(List list) : super.from(list);

  @override
  dynamic operator [](int index) {
    return _list[index];
  }
}

class PluginMap<K, V> extends Object with MapMixin<K, V> implements Map<K, V> {
  final Map _map;

  PluginMap.from(this._map);

  @override
  void forEach(void Function(K key, V value) action) {
    _map.forEach((key, value) {
      action(key, value);
    });
  }

  @override
  operator [](Object key) {
    return _map[key];
  }

  @override
  void operator []=(K key, value) {
    throw "unsupported";
    //_map[key] = value;
  }

  @override
  void clear() {
    throw "unsupported";
    //_map.clear();
  }

  @override
  Iterable<K> get keys => new List.from(_map.keys);

  @override
  remove(Object key) {
    throw "unsupported";
    // _map.remove(key);
  }

  @override
  toString() {
    return _map.toString();
  }

  @override
  Iterable<V> get values => new List.from(_map.values);

  Map toJson() {
    return this;
  }

  @override
  int get length => _map.length;
}

class Row extends PluginMap<String, dynamic> {
  Row.from(Map _map) : super.from(_map);
}

abstract class PluginList<T> extends Object
    with ListMixin<T>
    implements List<T> {
  final List _list;

  PluginList.from(List list) : _list = list;

  @override
  void forEach(void Function(T element) action) {
    for (int i = 0; i < _list.length; i++) {
      action(this[i]);
    }
  }

  @override
  Iterator<T> get iterator => new PluginIterator(this);

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    throw "unsupported";
  }

  @override
  void operator []=(int index, T value) {
    throw "unsupported";
  }

  @override
  String toString() {
    return _list.toString();
  }

  List toJson() {
    return this;
  }

  @override
  T get first {
    return this[0];
  }

  @override
  T get last {
    return this[length - 1];
  }
}
