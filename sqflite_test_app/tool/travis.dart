//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 command or run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart
import 'package:process_run/shell_run.dart';
import 'package:pub_semver/pub_semver.dart';

Future<void> main() async {
  final shell = Shell();

  final nnbdEnabled = dartVersion > Version(2, 11, 0, pre: '0');
  if (nnbdEnabled) {
    // Temp dart extra option. To remove once nnbd supported on stable without flags
    const dartExtraOptions = '--enable-experiment=non-nullable';
    // Needed for run and test
    const dartRunExtraOptions = '$dartExtraOptions --no-sound-null-safety';
    await shell.run('''

flutter format --set-exit-if-changed lib test tool
flutter analyze --no-current-package lib test tool
flutter test $dartRunExtraOptions

''');
  }
}
