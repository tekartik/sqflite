import 'package:process_run/shell_run.dart';

// Example
// dart run tool/flutter_run.dart -d emulator-5554
// dart run tool/flutter_run.dart -d emulator-5556
Future<void> main(List<String> arguments) async {
  final shell = Shell();

  await shell.run('''
flutter run -d chrome --wasm
''');
}
