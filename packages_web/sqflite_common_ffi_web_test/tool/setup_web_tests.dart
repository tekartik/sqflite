import 'package:sqflite_common_ffi_web/setup.dart';

Future<void> main() async {
  await setupWebTests();
}

Future<void> setupWebTests({bool? force}) async {
  await setupSqfliteWebBinaries(
    options: SqfliteWebSetupOptions(verbose: true, dir: 'test', force: force),
  );
}
