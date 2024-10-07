import 'dart:convert';
import 'dart:io';
import 'package:process_run/process_run.dart';

/// Create an iOS test project
Future<void> createIOSTestProject() async {
  await createTestProject(platform: 'ios');
}

/// Create a macOS test project
Future<void> createMacOSTestProject() async {
  await createTestProject(platform: 'macos');
}

/// Create a test project (to call in the proper directory)
Future<void> createTestProject({required String platform}) async {
  Future<void> cleanDirString(String path) async {
    var directory = Directory(path);
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  }

  await cleanDirString(platform);
  await cleanDirString('build');

  await run('flutter clean');
  await run('flutter create --platforms $platform .');
}

/// Run macOS
Future<void> runMacOS() async {
  await run('flutter run -d macos');
}

/// Find the first iOS device id
Future<String> findFirstIOSDeviceId() async {
  var list = jsonDecode(
      (await run('flutter devices --machine', verbose: false)).outText) as List;
  // "name": "iPhone 15 Pro",
  // "id": "1A9A31FE-40DC-4EEB-B464-63BBA43FC943",
  // "isSupported": true,
  for (var item in list) {
    var map = item as Map;
    var targetPlatform = map['targetPlatform'] as String;
    var name = map['name'] as String;
    var id = map['id'] as String;
    if (targetPlatform == 'ios') {
      stdout.writeln('Found iOS device $name $id');
      return id;
    }
  }
  throw 'No iOS device found';
}

/// Run iOS
Future<void> runIOS() async {
  var iosDeviceId = await findFirstIOSDeviceId();
  await run('flutter run -d $iosDeviceId');
}
