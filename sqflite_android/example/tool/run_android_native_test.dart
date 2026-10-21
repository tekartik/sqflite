import 'package:process_run/shell.dart';

Future<void> main(List<String> arguments) async {
  var shell = Shell(workingDirectory: 'android');
  await shell.run('''
 # Java unit test (only the plugin ones, the integration_test plugin unit tests
 # fail on JDK 25+ with its Mockito/Byte Buddy version)
./gradlew :sqflite_android:test

# With a emulator running
./gradlew connectedAndroidTest
 ''');
}
