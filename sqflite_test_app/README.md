# sqflite test app

Test application of the sqflite repository: the sqflite example pages
(`sqflite_example_common`) on every implementation, and runners of the shared
`sqflite_common_test` suite.

| Platform | Default implementation |
|---|---|
| Android, iOS, macOS | sqflite plugin |
| Linux, Windows | `sqflite_common_ffi` |
| Web | `sqflite_common_ffi_web` (setup needed, see below) |

## Getting Started

The platform folders are not checked in, create them first, in this
directory:

```bash
flutter create .
flutter run
```

Other entry points: `lib/main_ffi.dart` (ffi everywhere),
`lib/main_ffi_async.dart` (`sqflite_common_ffi_async`),
`lib/main_sqflite.dart` (plugin, with the plugin test page),
`lib/main_logger.dart` (queries logged), `lib/main_dev.dart` (verbose logs),
e.g. `flutter run -t lib/main_ffi.dart`.

### Web support

```bash
# Create the project
flutter create --platforms web .
# Setup the binaries (sqlite3.wasm and the shared worker)
dart run sqflite_common_ffi_web:setup
# Run it
flutter run -d chrome
```

After upgrading `sqflite_common_ffi_web` or `sqflite_common_ffi`, run the
setup again with `--force`.

## Shared test suite runners

They run every `sqflite_common_test` suite (`all.run(context)`).

Results and exit code on the host (integration test):

```bash
# Global factory: sqflite plugin on Android, iOS and macOS, ffi on Linux and
# Windows
flutter test integration_test/sqflite_test.dart -d <device id>
# or (SQFLITE_TEST_DEVICE_ID picks the device)
dart run tool/run_integration_test.dart
```

Results in the `flutter run` console:

```bash
# sqflite plugin factory (Android, iOS, macOS)
flutter run -t lib/test_main.dart
# ffi (io platforms)
flutter run -t lib/test_ffi_main.dart
# global factory, as the integration test
flutter run -t lib/main_sqflite_test_runner.dart
```

On the host, the ffi suite also runs as a unit test:

```bash
flutter test test/sqflite_ffi_test.dart
```

## Included test_driver

Flutter driver test to execute.

### On Android

Start emulator, then:

```
flutter driver --target=test_driver/main.dart
```

or

```
dart tool/run_flutter_driver_test.dart
```

or

```
flutter driver --target=test_driver/main.dart -d emulator-5554
```

### On Windows

(Powershell)

Optional first step (if not done yet or if the project does not work anymore)

```
# Delete existing windows project if needed
rmdir -Recurse -Force windows

# Recreate the project
flutter create --platforms windows .
```

Run in debug mode

```
# Run
flutter run
```

Build and run in release mode (`sqlite3.dll` is built and bundled by the
`sqlite3` package build hook)

```
# Build
flutter build windows

# Run it
.\build\windows\x64\runner\Release\sqflite_test_app.exe
```

or `dart run tool/create_build_and_run_release.dart` (Linux, macOS and
Windows: creates, builds and runs the release app).
