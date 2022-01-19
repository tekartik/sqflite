import 'dart:io';

import 'package:process_run/shell.dart';

Future<void> main() async {
  /// Add extra tools to build on linux
  ///
  /// Can only be called from CI without any sudo access issue.
  if (Platform.isLinux) {
    await Shell().run('tool/setup_linux_env.sh');
  }
}
