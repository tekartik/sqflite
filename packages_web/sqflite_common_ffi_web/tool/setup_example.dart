import 'package:sqflite_common_ffi_web/setup.dart';

Future<void> main() async {
  await setupExample();
}

Future<void> setupExample() async {
  await setupSqfliteWebBinaries(
    options: SqfliteWebSetupOptions(dir: 'example'),
  );
}
