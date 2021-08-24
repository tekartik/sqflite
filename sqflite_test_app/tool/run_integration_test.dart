import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future<void> main() async {
  await runIntegrationTest();
}

Future<void> runIntegrationTest({String? deviceId}) async {
  final shell = Shell();

  final nnbdEnabled = dartVersion > Version(2, 12, 0, pre: '0');
  if (nnbdEnabled) {
    // Temp dart extra option. To remove once nnbd supported on stable without flags
    const dartExtraOptions = '--enable-experiment=non-nullable';
    // Needed for run and test
    const dartRunExtraOptions = '$dartExtraOptions --no-sound-null-safety';
    await shell.run(
        'flutter drive ${deviceId != null ? '-d $deviceId ' : ''}$dartRunExtraOptions'
        ' --no-pub'
        ' --driver=test_driver/integration_test.dart'
        ' --target=integration_test/sqflite_test.dart');
  }
}
