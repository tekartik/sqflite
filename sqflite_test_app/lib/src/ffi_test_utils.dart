import 'dart:io';

import 'package:dev_test/build_support.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

/// True on io windows
var platformIsWindows = Platform.isWindows;

/// True on io linux
var platformIsLinux = Platform.isLinux;

/// True on io MacOS
var platformIsMacOS = Platform.isMacOS;

/// True for supported platform
var isSupported = platformIsWindows || platformIsLinux || platformIsMacOS;

/// Platform
var platform =
    platformIsWindows ? 'windows' : (platformIsMacOS ? 'macos' : 'linux');

var _linuxExeDir = join('build', 'linux', 'x64', 'release', 'bundle');
var _windowsExeDir = join('build', 'windows', 'runner', 'Release');
var _macOSExeDir = join('build', 'macos', 'Build', 'Products', 'Release');

/// Safe delete a directory
Future<void> deleteDir(String path) async {
  try {
    await Directory(path).delete(recursive: true);
  } catch (_) {}
}

/// Safe delete a file
Future<void> deleteFile(String path) async {
  try {
    await File(path).delete(recursive: true);
  } catch (_) {}
}

/// release exe dir (linux and windows for now)
String get platformExeDir => Platform.isLinux
    ? _linuxExeDir
    : (Platform.isMacOS ? _macOSExeDir : _windowsExeDir);

/// Windows platform
var buildPlatformWindows = 'windows';

/// MacOS platform
var buildPlatformMacOS = 'macos';

/// Linux platform
var buildPlatformLinux = 'linux';

/// Current build platform
/// Desktop only
String get buildPlatformCurrent {
  if (Platform.isWindows) {
    return buildPlatformWindows;
  } else if (Platform.isLinux) {
    return buildPlatformLinux;
  } else if (Platform.isMacOS) {
    return buildPlatformMacOS;
  } else {
    throw UnsupportedError('Unsupported platform');
  }
}

/// Force re-creating a project
Future<void> createProject(String path, {String? platform}) async {
  platform ??= buildPlatformCurrent;
  var shell = Shell(workingDirectory: path);

  // Delete platform directory
  await deleteDir(join(path, platform));
  // Create directory
  await Directory(path).create(recursive: true);
  await shell.run('flutter config --enable-$platform-desktop');
  await shell.run('flutter create --platforms $platform .');
}

/// Run the released
Future<void> runBuiltProject(String path) async {
  var appName = await getBuildProjectAppFilename(path);
  var shell = Shell(workingDirectory: join(platformExeDir, path));
  await shell.run(join('.', appName));
}

/// Get the app name
Future<String> getBuildProjectAppFilename(String path) async {
  var appName = (await pathGetPubspecYamlMap(path))['name'] as String;
  if (platformIsWindows) {
    appName = '$appName.exe';
  } else if (platformIsMacOS) {
    appName = '$appName.app';
  }
  return appName;
}

/// Recreate and build a project
Future<void> buildProject(String path,
    {String? target, String? platform}) async {
  var shell = Shell(workingDirectory: path);
  platform ??= buildPlatformCurrent;
  await shell.run('''
    flutter build $platform${target != null ? ' --target ${shellArgument(target)}' : ''}
    ''');
}
