import 'dart:core';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

/// Sqflite channel name
const _channelName = 'com.tekartik.sqflite';

/// Sqflite channel
@visibleForTesting
const methodChannel = MethodChannel(_channelName);

/// Invoke a native method
Future<T> invokeMethod<T>(String method, [Object? arguments]) async =>
    await methodChannel.invokeMethod<T>(method, arguments) as T;
