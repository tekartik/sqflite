import 'dart:io';
import 'package:process_run/shell_run.dart';

Future main() async {
  if (Platform.isLinux) {
    // Assuming ubuntu, to run as sudo
    await run('sudo apt-get -y install sqlite3 libsqlite3-dev');
  }
}
