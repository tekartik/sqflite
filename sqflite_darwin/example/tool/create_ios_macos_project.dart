import 'package:process_run/shell.dart';

Future<void> main() async {
  await run('flutter create --platforms ios,macos .');
}
