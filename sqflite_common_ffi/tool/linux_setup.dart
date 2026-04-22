import 'dart:io';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

Future main() async {
  if (Platform.isLinux) {
    // Assuming ubuntu, to run as root, this is mainly for CI
    await run('sudo apt-get -y install libsqlite3-0 libsqlite3-dev');
  } else if (Platform.isWindows) {
    await run('flutter build windows');
    var source = join(
      dirname(dirname(Platform.script.toFilePath())),
      'lib',
      'src',
      'windows',
      'sqlite3.dll',
    );
    for (var releasePath in [
      join('build', 'windows', 'runner', 'Release'),
      join('build', 'windows', 'x64', 'runner', 'Release'),
    ]) {
      var destDir = Directory(releasePath);
      if (destDir.existsSync()) {
        await File(source).copy(join(releasePath, 'sqlite3.dll'));
      }
    }
  }
}
