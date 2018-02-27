import 'dart:async';
import 'dart:collection';
import 'dart:core';

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

// Starting Dart preview 2, wrap the result
class Rows extends PluginList<Map<String, dynamic>> {
  Rows.from(List list) : super.from(list);

  @override
  Map<String, dynamic> operator [](int index) {
    Map item = rawList[index];
    if (item is Map<String, dynamic>) {
      return item;
    }
    return item.cast<String, dynamic>();
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

abstract class PluginList<T> extends ListBase<T> {
  final List _list;

  PluginList.from(List list) : _list = list;

  List get rawList => _list;

  dynamic rawElementAt(int index) => _list[index];

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
}
