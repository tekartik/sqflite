import 'dart:io';
import 'package:process_run/shell_run.dart';

Future main() async {
  if (Platform.isLinux) {
    // Assuming ubuntu, to run as root
    await run('apt-get -y install libsqlite3-0 libsqlite3-dev');
  }
}
