import 'dart:io';

import 'package:process_run/shell.dart';

Future<void> main() async {
  /// Add extra tools to build on linux
  ///
  /// Can only be called from CI without any sudo access issue.
  if (Platform.isLinux) {
    // Assuming ubuntu, to run as sudo
    await run('sudo apt-get -y install sqlite3 libsqlite3-dev');
    await Shell().run('tool/setup_linux_env.sh');
  }
}
