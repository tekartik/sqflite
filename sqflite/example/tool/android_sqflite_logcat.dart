import 'package:process_run/shell.dart';
import 'package:sqflite_example/src/common_import.dart';

Future<void> main() async {
  final StreamController<List<int>> controller = StreamController<List<int>>();
  final Shell shell = Shell(stdout: controller.sink, verbose: false);

  controller.stream
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) {
    if (line.contains('Sqflite')) {
      print('$line');
    }
  });

  await shell.run('adb logcat');

  // We'll never get there actually...
  await controller.close();
}
