import 'package:process_run/shell_run.dart';
import 'package:pub_semver/pub_semver.dart';

// Example
// dart run tool/flutter_run.dart -d emulator-5554
// dart run tool/flutter_run.dart -d emulator-5556
Future<void> main(List<String> arguments) async {
  final shell = Shell();

  final nnbdEnabled = dartVersion > Version(2, 11, 0, pre: '0');
  String dartRunExtraOptions;
  if (nnbdEnabled) {
    // Temp dart extra option. To remove once nnbd supported on stable without flags
    // final dartExtraOptions = '--enable-experiment=non-nullable';
    // Needed for run and test
    dartRunExtraOptions =
        '--enable-experiment=non-nullable --no-sound-null-safety';

    await shell.run('''

flutter run $dartRunExtraOptions ${shellArguments(arguments)}

''');
  }
}
