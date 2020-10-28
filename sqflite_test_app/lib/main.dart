import 'main_io.dart' if (dart.library.html) 'main_web.dart' as impl;

Future<void> main() async {
  impl.main();
}
