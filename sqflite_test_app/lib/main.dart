import 'package:sqflite_test_app/src/import.dart'; // ignore: unused_import

import 'main_io.dart' if (dart.library.js_interop) 'main_web.dart' as impl;

Future<void> main() async {
  await mainSqfliteTestApp();
}

/// Main sqflite test app.
Future<void> mainSqfliteTestApp() async {
  impl.main();
}
