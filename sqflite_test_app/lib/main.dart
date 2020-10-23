import 'main_io.dart' as impl if (dart.library.html) 'main_web.dart';

Future<void> main() async {
  await impl.main();
}
