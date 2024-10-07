import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

/// Check if spm is enabled
Future<bool> flutterHasSpmEnabled() async {
  var lines = (await run('flutter config --list', verbose: false)).outLines;
  for (var line in lines) {
    var parts = line.split(':').map((e) => e.trim()).toList();
    if (parts.length == 2) {
      if (parts[0] == 'enable-swift-package-manager') {
        return parts[1] == 'true';
      }
    }
  }
  return false;
}

/// Min supported SPM version (as of 2024-10-07 on main channel)
var minSpmFlutterVersion = Version(3, 26, 0, pre: '0');

/// Enable spm
Future<void> enableSpm() async {
  var flutterVersion = (await getFlutterBinVersion())!;
  if (flutterVersion < minSpmFlutterVersion) {
    throw 'Flutter version $flutterVersion is not supported for spm (min: $minSpmFlutterVersion)';
  }
  var spmEnabled = await flutterHasSpmEnabled();
  if (spmEnabled) {
    stdout.writeln('SPM already enabled');
    return;
  }
  await run('flutter config --enable-swift-package-manager');
}

/// Enable spm
Future<void> disableSpm() async {
  var spmEnabled = await flutterHasSpmEnabled();
  if (!spmEnabled) {
    stdout.writeln('SPM already disabled');
    return;
  }
  await run('flutter config --no-enable-swift-package-manager');
}
