import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';

/// Plugin test context (Android, iOS, macOS).
class SqflitePluginTestContext extends SqfliteLocalTestContext {
  /// Plugin test context (Android, iOS, macOS).
  SqflitePluginTestContext()
    : super(databaseFactory: databaseFactorySqflitePlugin);

  @override
  bool get isPlugin => true;

  @override
  bool get supportsRecoveredInTransaction => true;
}

/// Test runner context
var testContext = SqflitePluginTestContext();

/// Runs sqflite_common_test on the sqflite plugin, results in the console:
///
/// `flutter run -t lib/main_sqflite_plugin_test_runner.dart -d <device id>`
///
/// (tool/run_test_runner.dart picks the device).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  all.run(testContext);
}
