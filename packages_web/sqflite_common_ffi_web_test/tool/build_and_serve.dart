// ignore: depend_on_referenced_packages
import 'package:dev_build/build_support.dart';
import 'package:path/path.dart';
import 'package:process_run/process_run.dart';

Future<void> main() async {
  await checkAndActivatePackage('dhttpd');
  await checkAndActivateWebdev();
  var shell = Shell();
  var port = 8080;
  await shell.run('dart pub global run webdev build -o web:build/web');
  shell = shell.cd(join('build', 'web'));
  print('http://localhost:$port');
  await shell.run('dart pub global run dhttpd .  --port $port .');
}
