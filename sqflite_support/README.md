# sqflite_support

Tooling of the [sqflite](https://github.com/tekartik/sqflite) repository: the
CI scripts and the helpers of the test apps. Not published, not meant to be
used outside this repository.

## CI scripts

Run from this folder (`dart pub get` first), each one is a GitHub workflow of
the repository:

| Script | Does |
|---|---|
| `dart run tool/run_ci.dart` | format, analyze and test the packages of the repository (format and analyze only for `sqflite_support` and `sqflite_test_app`) |
| `dart run tool/run_ci_build.dart` | the tests of `sqflite_support` and `sqflite_test_app`, which build apps |
| `dart run tool/run_ci_android.dart` | creates an app adding the sqflite example and builds its apk, builds the apks of `sqflite_android/example` and `sqflite_test_app` and runs their Java unit tests (`./gradlew test`) |
| `dart run tool/run_ci_ios.dart`, `dart run tool/run_ci_macos.dart` | creates an app adding the sqflite example and builds it for iOS (no code signing) or macOS |
| `dart run tool/run_ci_web.dart` | format, analyze and test `packages_web/sqflite_common_ffi_web` |
| `dart run tool/setup_env.dart` | Linux only: `sudo apt-get install` of the build dependencies (SQLite, GTK, ninja) |

## Test app helpers (lib/)

Used by the tools of the test apps (for example
`packages_flutter/sqflite_plugin_test_app/tool/`):

* `flutter_device.dart`: picks the device to run on (`SQFLITE_TEST_DEVICE_ID`
  when set, the only phone/emulator/simulator connected, or a choice in the
  console) and creates the missing platform folders of a test app.
* `flutter_test_runner.dart`: `runFlutterTestRunner()` runs a console test
  runner with `flutter run` and quits once the tests are done (exit code 1 if
  some failed).
* `spm.dart`: turns the Swift Package Manager support of Flutter on or off.
* `test_project.dart`: creates and runs iOS/macOS test projects.
