import 'dart:async';
import 'dart:io';

import 'package:dev_build/shell.dart';

/// The tool argument keeping `flutter run` attached once the tests are done,
/// `R` (hot restart) then runs them again.
const flutterTestRunnerNoQuitArg = '--no-quit';

/// The summary printed by package:test once the tests are done, for example
/// `00:08 +160 ~14: All tests passed!` or
/// `00:08 +159 ~14 -1: Some tests failed.` (prefixed by `flutter: ` or
/// `I/flutter (1234): ` in the `flutter run` output).
final _testsDoneRegExp = RegExp(
  r'\d+:\d+ \+\d+.*: (All tests passed!|Some tests failed\.)',
);

/// Color escape sequences of the test output.
final _ansiEscapeRegExp = RegExp(r'\x1B\[[0-9;]*m');

/// The exit code if [line] is the summary printed once the tests are done:
/// 0 if all the tests passed, 1 if some failed, otherwise null.
int? flutterTestRunnerDoneExitCode(String line) {
  var match = _testsDoneRegExp.firstMatch(
    line.replaceAll(_ansiEscapeRegExp, ''),
  );
  if (match == null) {
    return null;
  }
  return match.group(1)!.startsWith('All') ? 0 : 1;
}

/// Runs the console test runner [target] (`flutter run -d [deviceId] -t
/// [target]`), the tests print their results in the console.
///
/// The console input (terminal or IDE) goes to `flutter run`: `q` + Enter
/// quits, `R` + Enter runs the tests again (hot restart).
///
/// Unless [quitWhenDone] is false, quits once the tests are done.
///
/// Returns the exit code: 0 if all the tests passed, 1 if some failed,
/// otherwise the one of `flutter run`.
Future<int> runFlutterTestRunner({
  required String deviceId,
  required String target,
  bool quitWhenDone = true,
}) async {
  // flutter run input: the console one, and q once the tests are done
  var input = ShellLinesController();
  var stdinSubscription = sharedStdIn.listen(input.sink.add);
  var output = ShellLinesController();
  var shell = Shell(
    stdin: input.binaryStream,
    stdout: output.sink,
    throwOnError: false,
  );

  int? testsExitCode;
  Timer? killTimer;
  output.stream.listen((line) {
    stdout.writeln(line);
    if (quitWhenDone && testsExitCode == null) {
      testsExitCode = flutterTestRunnerDoneExitCode(line);
      if (testsExitCode != null) {
        // Same as typing q, flutter run stops the app and exits
        input.write('q');
        killTimer = Timer(const Duration(seconds: 30), shell.kill);
      }
    }
  });
  try {
    var result = (await shell.run('flutter run -d $deviceId -t $target')).first;
    return testsExitCode ?? result.exitCode;
  } on ShellException catch (_) {
    // Killed, flutter run did not quit
    var exitCode = testsExitCode;
    if (exitCode != null) {
      return exitCode;
    }
    rethrow;
  } finally {
    killTimer?.cancel();
    await stdinSubscription.cancel();
    await sharedStdIn.terminate();
    input.close();
    output.close();
  }
}
