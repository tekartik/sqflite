# sqflite_ffi_test_app

sqflite_ffi test application.

Runs the sqflite example app on top of `sqflite_ffi` (the default database
factory being registered automatically by the plugin) with an additional
`Sqflite ffi tests` page testing the sqflite isolate sharing between flutter
isolates using `IsolateNameServer`.

## Running the tests

```bash
flutter test
```

## Running the app

```bash
flutter run
```

## Running sqflite_common_test on a device

The device is `SQFLITE_TEST_DEVICE_ID` when set (`ds env var set
SQFLITE_TEST_DEVICE_ID emulator-5554`), the only phone, emulator or simulator
connected, or the one picked in the list (the plugin twin is
`sqflite_plugin_test_app`).

```bash
# Integration test, results and exit code on the host
dart run tool/run_integration_test.dart
# Integration test on the host (linux, macos or windows)
dart run tool/run_integration_test_host.dart
# Console runner, results in the flutter run console
dart run tool/run_test_runner.dart
# Console runner on the host (linux, macos or windows)
dart run tool/run_test_runner_host.dart
```

The console runners quit once the tests are done (exit code 1 if some
failed). With `--no-quit` they stay attached: the console input goes to
`flutter run`, `R` + Enter runs the tests again, `q` + Enter quits.
