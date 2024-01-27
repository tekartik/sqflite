import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_darwin/sqflite_darwin.dart';
import 'package:sqflite_darwin/src/sqflite_darwin.dart';
import 'package:sqflite_darwin/src/sqflite_darwin_platform_interface.dart';
import 'package:sqflite_darwin/src/sqflite_darwin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSqfliteDarwinPlatform
    with MockPlatformInterfaceMixin
    implements SqfliteDarwinPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SqfliteDarwinPlatform initialPlatform = SqfliteDarwinPlatform.instance;

  test('$MethodChannelSqfliteDarwin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSqfliteDarwin>());
  });

  test('getPlatformVersion', () async {
    SqfliteDarwin sqfliteDarwinPlugin = SqfliteDarwin();
    MockSqfliteDarwinPlatform fakePlatform = MockSqfliteDarwinPlatform();
    SqfliteDarwinPlatform.instance = fakePlatform;

    expect(await sqfliteDarwinPlugin.getPlatformVersion(), '42');
  });
}
