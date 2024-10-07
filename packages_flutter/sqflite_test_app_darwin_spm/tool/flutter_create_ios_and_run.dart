import 'package:sqflite_support/spm.dart';
import 'package:sqflite_support/test_project.dart';

Future<void> main() async {
  await enableSpm();
  await createIOSTestProject();
  await runIOS();
}
