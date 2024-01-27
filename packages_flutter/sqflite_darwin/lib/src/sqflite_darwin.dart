import 'sqflite_darwin_platform_interface.dart';

class SqfliteDarwin {
  Future<String?> getPlatformVersion() {
    return SqfliteDarwinPlatform.instance.getPlatformVersion();
  }
}
