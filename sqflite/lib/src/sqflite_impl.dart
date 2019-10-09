import 'dart:async';
import 'dart:core';

import 'services_impl.dart';

export 'package:sqflite/src/collection_utils.dart';
export 'package:sqflite/src/utils.dart';

/// Sqflite channel name
const String channelName = 'com.tekartik.sqflite';

/// Sqflite channel
const MethodChannel channel = MethodChannel(channelName);

/// Temp flag to test concurrent reads
final bool supportsConcurrency = false;

/// Invoke a native method
Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
    channel.invokeMethod<T>(method, arguments);
