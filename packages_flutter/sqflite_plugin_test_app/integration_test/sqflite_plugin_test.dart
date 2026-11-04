import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_plugin_test_app/main_sqflite_plugin_test_runner.dart';

/// sqflite_common_test on the sqflite plugin in the app, results and exit
/// code on the host:
///
/// `flutter test integration_test -d <device id>`
///
/// (tool/run_integration_test.dart picks the device).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A flutter_test group, so that the package:test tests declared inside are
  // seen by integration_test.
  group('plugin', () {
    all.run(testContext);
  });
}
