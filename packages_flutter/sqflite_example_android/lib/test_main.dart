import 'package:flutter/widgets.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

/// Android plugin test context
class SqfliteAndroidTestContext extends SqfliteLocalTestContext {
  /// Android plugin test context
  SqfliteAndroidTestContext()
    : super(databaseFactory: SqflitePlatform.databaseFactoryMethodChannel);

  @override
  bool get isPlugin => true;

  @override
  bool get supportsRecoveredInTransaction => true;
}

/// Runs sqflite_common_test on the Android plugin, results in the console:
///
/// flutter create --platforms android --empty . # once, android/ is ignored
/// flutter run -t lib/test_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  all.run(SqfliteAndroidTestContext());
}
