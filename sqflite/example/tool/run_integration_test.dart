//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 command and run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future<void> main() async {
  await runIntegrationTest();
}

Future<void> runIntegrationTest({String deviceId}) async {
  final shell = Shell();

  final nnbdEnabled = dartVersion > Version(2, 11, 0, pre: '0');
  if (nnbdEnabled) {
    // Temp dart extra option. To remove once nnbd supported on stable without flags
    const dartExtraOptions = '--enable-experiment=non-nullable';
    // Needed for run and test
    const dartRunExtraOptions = '$dartExtraOptions --no-sound-null-safety';
    await shell.pushd('android').run(
        'flutter drive ${deviceId != null ? '-d $deviceId ' : ''}$dartRunExtraOptions'
        ' --driver=test_driver/integration_test.dart'
        ' --target=integration_test/sqflite_test.dart');
  }
}
