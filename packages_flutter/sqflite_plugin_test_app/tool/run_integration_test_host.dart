import 'package:dev_build/shell.dart';
import 'package:sqflite_support/flutter_device.dart';

/// Runs integration_test/sqflite_plugin_test.dart on the host: linux, macos or
/// windows (its platform folder is created when missing).
Future<void> main() async {
  var platform = flutterHostPlatform;
  await flutterCreatePlatforms([platform]);
  await run('flutter test integration_test -d $platform');
}
