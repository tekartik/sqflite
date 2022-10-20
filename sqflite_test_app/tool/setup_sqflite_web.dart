import 'package:process_run/shell.dart';

Future<void> main() async {
  await run('''
    # Create the web project
    flutter create . --platforms web
    # Build and copy the binaries
    flutter pub run sqflite_common_ffi_web:setup --force
''');
}
