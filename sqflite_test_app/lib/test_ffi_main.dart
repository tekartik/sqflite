import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';

/// Ffi test context
class SqfliteFfiTestContext extends SqfliteLocalTestContext {
  /// Ffi test context
  SqfliteFfiTestContext() : super(databaseFactory: databaseFactoryFfi);

  @override
  bool get supportsUri => true;
}

/// Runs sqflite_common_test on ffi (io only), results in the console:
///
/// flutter run -t lib/test_ffi_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  // The ffi default databases path is relative to the current directory,
  // use the plugin one where available.
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await databaseFactoryFfi.setDatabasesPath(
      await databaseFactorySqflitePlugin.getDatabasesPath(),
    );
  }
  all.run(SqfliteFfiTestContext());
}
