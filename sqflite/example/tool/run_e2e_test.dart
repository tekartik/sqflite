import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_example/utils.dart';

Future<void> main() async {
  final Shell shell = Shell();

// # flutter driver --driver=test_driver/sqflite_e2e_test.dart test_driver/sqflite_e2e.dart
  await shell.run('flutter build apk');
  var dir = absolute(Directory.current.path);
  var target = join(dir, 'test/sqflite_e2e.dart');
  print(target);
  await shell.pushd('android').run('''
 ./gradlew app:connectedAndroidTest -Ptarget=$target
''');
}
