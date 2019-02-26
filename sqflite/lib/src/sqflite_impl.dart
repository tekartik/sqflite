import 'dart:async';
import 'dart:core';

import 'services_impl.dart';

export 'package:sqflite/src/collection_utils.dart';
export 'package:sqflite/src/utils.dart';

const String channelName = 'com.tekartik.sqflite';

const MethodChannel channel = MethodChannel(channelName);

// Temp flag to test concurrent reads
final bool supportsConcurrency = false;

// Make it async safe for dart 2.0.0-dev28+ preview dart 2
Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
  final T result = await channel.invokeMethod(method, arguments) as T;
  return result;
}
