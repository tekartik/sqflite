import 'package:dev_build/shell.dart';
import 'package:sqflite_support/flutter_device.dart';

/// Runs lib/main_sqflite_plugin_test_runner.dart (results in the console) on
/// the host: linux, macos or windows (its platform folder is created when
/// missing).
Future<void> main() async {
  var platform = flutterHostPlatform;
  await flutterCreatePlatforms([platform]);
  await run(
    'flutter run -d $platform -t lib/main_sqflite_plugin_test_runner.dart',
  );
}
