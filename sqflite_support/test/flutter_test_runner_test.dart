import 'package:sqflite_support/flutter_test_runner.dart';
import 'package:test/test.dart';

void main() {
  test('flutterTestRunnerDoneExitCode', () {
    expect(
      flutterTestRunnerDoneExitCode(
        'flutter: 00:08 +160 ~14: All tests passed!',
      ),
      0,
    );
    expect(
      flutterTestRunnerDoneExitCode(
        'flutter: 00:08 +159 ~14 -1: Some tests failed.',
      ),
      1,
    );
    // Android and colors
    expect(
      flutterTestRunnerDoneExitCode(
        'I/flutter (12345): 00:08 \x1B[32m+160\x1B[0m\x1B[33m ~14\x1B[0m:'
        ' All tests passed!\x1B[0m',
      ),
      0,
    );
    expect(
      flutterTestRunnerDoneExitCode(
        'flutter: 00:08 \x1B[32m+159\x1B[0m\x1B[33m ~14\x1B[0m\x1B[31m'
        ' -1\x1B[0m: \x1B[31mSome tests failed.\x1B[0m',
      ),
      1,
    );
    expect(
      flutterTestRunnerDoneExitCode('flutter: 00:08 +155 ~9: wal wal files'),
      isNull,
    );
    expect(flutterTestRunnerDoneExitCode('Flutter run key commands.'), isNull);
  });
}
