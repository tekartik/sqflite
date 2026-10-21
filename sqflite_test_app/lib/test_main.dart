import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_test_app/test/io_tests.dart';

/// Plugin test context (Android, iOS, macOS)
class SqflitePluginTestContext extends SqfliteLocalTestContext {
  /// Plugin test context (Android, iOS, macOS)
  SqflitePluginTestContext()
    : super(databaseFactory: databaseFactorySqflitePlugin);

  @override
  bool get isPlugin => true;

  @override
  bool get supportsRecoveredInTransaction => true;
}

/// Runs sqflite_common_test on the sqflite plugin (Android, iOS, macOS),
/// results in the console:
///
/// flutter run -t lib/test_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var context = SqflitePluginTestContext();
  all.run(context);
  runIoTests(context);
}
