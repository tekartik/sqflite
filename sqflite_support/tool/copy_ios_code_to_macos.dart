import 'package:process_run/shell.dart';

Future<void> main() async {
  final shell = Shell(workingDirectory: '..');

  await shell.run('''
# Code is shared between ios and macos
# There is no easy way to do that so the macos code is the reference
# and is copied to ios
cp -R sqflite/ios/Classes/ sqflite/macos/Classes/

''');
}
