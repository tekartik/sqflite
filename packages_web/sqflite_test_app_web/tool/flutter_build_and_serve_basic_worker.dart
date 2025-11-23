import 'package:dev_build/build_support.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

Future<void> main() async {
  await checkAndActivatePackage('dhttpd');
  var shell = Shell();
  await shell.run('''
      flutter build web -t lib/main_web_simple_worker.dart''');
  shell = shell.cd(join('build', 'web'));
  // ignore: avoid_print
  print('http://localhost:8080');

  await shell.run(
    'dart pub global run dhttpd:dhttpd . --headers=Cross-Origin-Embedder-Policy=credentialless;Cross-Origin-Opener-Policy=same-origin',
  );
}
