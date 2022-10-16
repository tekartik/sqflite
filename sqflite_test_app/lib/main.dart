import 'main_io.dart' if (dart.library.html) 'main_web.dart' as impl;

Future<void> main() async {
  await mainSqfliteTestApp();
}

/// Main sqflite test app.
Future<void> mainSqfliteTestApp() async {
  impl.main();
}
