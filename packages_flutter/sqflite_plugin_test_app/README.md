# sqflite_plugin_test_app

Runs `sqflite_common_test` on the sqflite plugin (Android, iOS, macOS),
without ffi (the ffi twin is `sqflite_ffi_test_app`).

The platform folders are generated and git ignored, the tool scripts create
them (`dart run tool/flutter_create.dart`).

The device is `SQFLITE_TEST_DEVICE_ID` when set (`ds env var set
SQFLITE_TEST_DEVICE_ID emulator-5554`), the only phone, emulator or simulator
connected, or the one picked in the list.

## Integration test (results and exit code on the host)

```bash
dart run tool/run_integration_test.dart
# On the host (linux, macos or windows; macOS is the only desktop the sqflite
# plugin implements)
dart run tool/run_integration_test_host.dart
# or
flutter test integration_test -d <device id>
```

## Console runner (results in the `flutter run` console)

```bash
dart run tool/run_test_runner.dart
# On the host (linux, macos or windows)
dart run tool/run_test_runner_host.dart
# or
flutter run -t lib/main_sqflite_plugin_test_runner.dart -d <device id>
```
