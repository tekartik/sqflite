import 'dart:io';

import 'package:http/io_client.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

Future<void> main() async {
  final shell = Shell();

  await shell.run('''

flutter format --set-exit-if-changed lib test tool
flutter analyze --no-current-package lib test tool
flutter test --no-pub --coverage

''');

  try {
    await run('dart test/no_flutter_main.dart', verbose: true);
  } catch (e) {
    stdout.writeln('error $e running test/no_flutter_main.dart');
  }

  // CODECOV_TOKEN must be defined on travis
  final codeCovToken = userEnvironment['SQFLITE_CODECOV_TOKEN'];
  final dartVersion = userEnvironment['TRAVIS_DART_VERSION'];

  if (dartVersion == 'stable') {
    if (codeCovToken != null) {
      String bashFilePath;
      try {
        final dir = await Directory.systemTemp.createTemp('sqflite');
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
    stdout.writeln('No code coverage for non-stable dart version $dartVersion');
  }
}
