import 'package:process_run/shell.dart';

Future<void> main(List<String> arguments) async {
  var shell = Shell(workingDirectory: 'android');
  await shell.run('''
 # Java unit test
./gradlew test

# With a emulator running
./gradlew connectedAndroidTest
 ''');
}
