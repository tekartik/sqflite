import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sqflite_darwin_platform_interface.dart';

/// An implementation of [SqfliteDarwinPlatform] that uses method channels.
class MethodChannelSqfliteDarwin extends SqfliteDarwinPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sqflite_darwin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
