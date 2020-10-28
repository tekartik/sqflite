// To run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart

import 'dart:io';

import 'package:http/io_client.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';
import 'package:pub_semver/pub_semver.dart';

Future<void> main() async {
  final shell = Shell();

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
pub run $dartRunExtraOptions test

''');

    // CODECOV_TOKEN must be defined on travis
    final codeCovToken = userEnvironment['CODECOV_TOKEN'];
    final travisDartChannel = userEnvironment['TRAVIS_DART_VERSION'];

    if (travisDartChannel == 'stable') {
      stdout.writeln('Publishing coverage information.');
      if (codeCovToken != null) {
        late String bashFilePath;
        try {
          final dir = await Directory.systemTemp.createTemp('sqflite_common');
          bashFilePath = join(dir.path, 'codecov.bash');
          await File(bashFilePath)
              .writeAsString(await IOClient().read('https://codecov.io/bash'));
          await shell.run('bash $bashFilePath');
        } catch (e) {
          stdout.writeln('error $e running $bashFilePath');
        }
      } else {
        stdout.writeln(
            'CODECOV_TOKEN not defined. Not publishing coverage information');
      }
    } else {
      stdout
          .writeln('No code coverage for non-stable dart version $dartVersion');
    }
  }
}
