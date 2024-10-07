import 'package:process_run/process_run.dart';
import 'package:sqflite_support/spm.dart';

Future<void> main() async {
  await disableSpm();
  var shell = Shell(workingDirectory: '../../sqflite_darwin');
  await shell.run('''
pod lib lint darwin/sqflite_darwin.podspec --configuration=Debug --skip-tests --use-modular-headers --use-libraries --allow-warnings
pod lib lint darwin/sqflite_darwin.podspec --configuration=Debug --skip-tests --use-modular-headers --allow-warnings
  
  ''');
}
