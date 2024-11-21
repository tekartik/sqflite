import 'setup_io.dart';

Future<void> main() async {
  var context = await getSetupContext();
  await context.copyBinaries();
}
