import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sqflite_darwin_method_channel.dart';

abstract class SqfliteDarwinPlatform extends PlatformInterface {
  /// Constructs a SqfliteDarwinPlatform.
  SqfliteDarwinPlatform() : super(token: _token);

  static final Object _token = Object();

  static SqfliteDarwinPlatform _instance = MethodChannelSqfliteDarwin();

  /// The default instance of [SqfliteDarwinPlatform] to use.
  ///
  /// Defaults to [MethodChannelSqfliteDarwin].
  static SqfliteDarwinPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SqfliteDarwinPlatform] when
  /// they register themselves.
  static set instance(SqfliteDarwinPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
