import 'package:sqflite_common_ffi_web/setup.dart';

Future<void> main() async {
  await setupExampleForce();
}

Future<void> setupExampleForce() async {
  await setupSqfliteWebBinaries(
    options: SqfliteWebSetupOptions(dir: 'example', force: true),
  );
}
