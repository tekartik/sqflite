# sqflite test app

Test application

## Getting Started

run in this directory:

```bash
flutter create  .
flutter run
```

### Web support

```bash
# Create the project
flutter create --platforms web .
# Setup the binaries
flutter pub run sqflite_common_ffi_web:setup
# Run it
flutter run -d chrome
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

Build and run in release mode
```
# Build
flutter build windows

# Copy sqlite3.dll
cp ..\sqflite_common_ffi\lib\src\windows\sqlite3.dll .\build\windows\runner\Release

# Run it
.\build\windows\runner\Release\sqflite_test_app.exe
```