import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

import 'linux_setup.dart' as linux_setup;

bool get runningOnTravis => Platform.environment['TRAVIS'] == 'true';

Future main() async {
  // print(Directory.current);
  var shell = Shell();

  if (runningOnTravis) {
    await linux_setup.main();
  }

  final nnbdEnabled = dartVersion > Version(2, 11, 0, pre: '0');
  if (nnbdEnabled) {
    // Temp dart extra option. To remove once nnbd supported on stable without flags
    final dartExtraOptions = '--enable-experiment=non-nullable';
    // Needed for run and test
    final dartRunExtraOptions =
        '--enable-experiment=non-nullable --no-sound-null-safety';

    await shell.run('''

dartanalyzer $dartExtraOptions --fatal-warnings --fatal-infos .
dartfmt -n --set-exit-if-changed .
pub run $dartRunExtraOptions test -p vm

# Remove chrom test - not working with NNBD: pub run $dartRunExtraOptions test -p chrome

''');
  }
}
