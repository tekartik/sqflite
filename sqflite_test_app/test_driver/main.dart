import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_example/src/common_import.dart';
import 'package:sqflite_test_app/setup_flutter.dart';

class SqfliteDriverTestContext extends SqfliteLocalTestContext {
  SqfliteDriverTestContext() : super(databaseFactory: databaseFactory);
}

var testContext = SqfliteDriverTestContext();

void main() {
  final completer = Completer<String>();
  enableFlutterDriverExtension(handler: (_) => completer.future);

  if (platform.isWindows || platform.isLinux) {
    sqfliteFfiInit();
    sqfliteFfiInitAsMockMethodCallHandler();
  }

  tearDownAll(() => completer.complete(''));

  group('driver', () {
    all.run(testContext);
  });

  if (platform.isAndroid) {
    group('driver with 2 threads', () {
      setUpAll(() async {
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        await Sqflite.devSetOptions(SqfliteOptions()..androidThreadCount = 2);
      });
      all.run(testContext);
    });
  }
}
