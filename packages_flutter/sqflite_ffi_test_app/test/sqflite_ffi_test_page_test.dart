import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_ffi_test_app/page/sqflite_ffi_test_page.dart';

/// Run the sqflite ffi test page tests (sqflite isolate shared between
/// flutter isolates using IsolateNameServer).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final page = SqfliteFfiTestPage();
  for (final pageTest in page.tests) {
    test(pageTest.name, () async {
      await pageTest.fn();
    });
  }
}
