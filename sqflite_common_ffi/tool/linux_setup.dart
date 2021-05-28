import 'dart:io';
import 'package:process_run/shell_run.dart';

Future main() async {
  if (Platform.isLinux) {
    // Assuming ubuntu, to run as root, this is mainly for CI
    await run('sudo apt-get -y install libsqlite3-0 libsqlite3-dev');
  }
}
