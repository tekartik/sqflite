import 'package:process_run/process_run.dart';

Future<void> main(List<String> args) async {
  var shell = Shell(workingDirectory: '../darwin');
  await shell.run('pod spec lint --verbose');
}
