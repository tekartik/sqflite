import 'package:flutter/services.dart';

import 'sqflite_darwin_platform_interface.dart';

const sqfliteDarwinMethodChannel = MethodChannel('sqflite_darwin');

/// An implementation of [SqfliteDarwinPlatform] that uses method channels.
class MethodChannelSqfliteDarwin extends SqfliteDarwinPlatform {
  /// The method channel used to interact with the native platform.

  @override
  Future<String?> getPlatformVersion() async {
    final version = await sqfliteDarwinMethodChannel
        .invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
