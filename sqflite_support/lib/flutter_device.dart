import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';

/// The env var giving the id of the device the test tools run on, for example
/// `emulator-5554`.
///
/// Read through process_run, so it can be set in the OS environment or in
/// the user environment (`ds env var set SQFLITE_TEST_DEVICE_ID <id>`,
/// `ds env var delete SQFLITE_TEST_DEVICE_ID`), which IDE runs see too.
const sqfliteTestDeviceIdEnvKey = 'SQFLITE_TEST_DEVICE_ID';

/// A supported device of `flutter devices --machine`.
class FlutterDeviceInfo {
  /// Id, the `-d` argument.
  final String id;

  /// Name.
  final String name;

  /// `android-arm64`, `android-x64`, `ios`, `darwin`, `linux-x64`,
  /// `windows-x64`, `web-javascript`...
  final String targetPlatform;

  /// True for an emulator or a simulator.
  final bool emulator;

  /// From a `flutter devices --machine` item.
  FlutterDeviceInfo.fromMap(Map map)
    : id = map['id'] as String,
      name = map['name'] as String,
      targetPlatform = map['targetPlatform'] as String,
      emulator = map['emulator'] == true;

  /// An Android or iOS device, emulator or simulator.
  bool get isMobile => targetPlatform.startsWith('android') || isIOS;

  /// An iOS device or simulator.
  bool get isIOS => targetPlatform == 'ios';

  @override
  String toString() =>
      '$name ($id, $targetPlatform${emulator ? ', emulator' : ''})';
}

/// The platform of the host, also its `flutter devices` id and its platform
/// folder: `linux`, `macos` or `windows`.
String get flutterHostPlatform => Platform.isMacOS
    ? 'macos'
    : Platform.isWindows
    ? 'windows'
    : 'linux';

/// Creates the missing platform folders of the flutter project in the current
/// directory (generated and git ignored in the test apps), `android`, `ios`,
/// `linux`, `macos`, `windows`, `web`.
Future<void> flutterCreatePlatforms(List<String> platforms) async {
  var missing = platforms
      .where((platform) => !Directory(platform).existsSync())
      .toList();
  if (missing.isNotEmpty) {
    await run(
      'flutter create --platforms ${missing.join(',')} --org com.tekartik'
      ' --empty .',
    );
  }
}

/// The supported devices of `flutter devices --machine`.
Future<List<FlutterDeviceInfo>> getFlutterDevices() async {
  var result = await run('flutter devices --machine', verbose: false);
  return (jsonDecode(result.outText) as List)
      .cast<Map>()
      .where((map) => map['isSupported'] != false)
      .map(FlutterDeviceInfo.fromMap)
      .toList();
}

/// The id of the device to run on:
/// - [sqfliteTestDeviceIdEnvKey] when set,
/// - the only connected device accepted by [where] (by default a phone, an
///   emulator or a simulator),
/// - otherwise the one picked in the list printed (read from stdin, which
///   works in a terminal and in an IDE run console).
Future<String> selectFlutterDeviceId({
  bool Function(FlutterDeviceInfo device)? where,
}) async {
  var envDeviceId = ShellEnvironment().vars[sqfliteTestDeviceIdEnvKey];
  if (envDeviceId != null && envDeviceId.isNotEmpty) {
    stdout.writeln('Device $envDeviceId (from $sqfliteTestDeviceIdEnvKey)');
    return envDeviceId;
  }
  where ??= (device) => device.isMobile;
  var devices = (await getFlutterDevices()).where(where).toList();
  if (devices.isEmpty) {
    throw StateError(
      'No device found: start an emulator (flutter emulators --launch <id>)'
      ' or a simulator, or set $sqfliteTestDeviceIdEnvKey',
    );
  }
  if (devices.length == 1) {
    stdout.writeln('Device ${devices.first}');
    return devices.first.id;
  }
  for (var i = 0; i < devices.length; i++) {
    stdout.writeln('${i + 1}: ${devices[i]}');
  }
  while (true) {
    stdout.write('Device [1-${devices.length}]: ');
    var line = stdin.readLineSync();
    if (line == null) {
      throw StateError('No device picked, set $sqfliteTestDeviceIdEnvKey');
    }
    var index = int.tryParse(line.trim());
    if (index != null && index >= 1 && index <= devices.length) {
      var id = devices[index - 1].id;
      stdout.writeln(
        'Not to be asked again: ds env var set $sqfliteTestDeviceIdEnvKey $id',
      );
      return id;
    }
  }
}
