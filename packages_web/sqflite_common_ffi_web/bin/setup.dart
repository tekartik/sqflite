import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

var webdevReady = () async {
  var shell = Shell();
  try {
    await shell.run('dart pub global run webdev --version');
  } catch (e) {
    await shell.run('dart pub global activate webdev');
  }
}();
Future<void> main() async {
  await webdevReady;
  await setupBinaries();
}
