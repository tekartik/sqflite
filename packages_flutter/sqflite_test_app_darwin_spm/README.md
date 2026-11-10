# sqflite test app (Swift Package Manager)

Test application of `sqflite_darwin` on iOS and macOS built with the Swift
Package Manager. Its twin `sqflite_test_app_darwin_pod` checks the CocoaPods
build.

The `ios/` and `macos/` folders are not tracked, the tools create them:

```bash
# Create the iOS project and run it on the first iOS device or simulator
dart run tool/flutter_create_ios_and_run.dart
# Create the macOS project and run it
dart run tool/flutter_create_macos_and_run.dart
# Lint the CocoaPods podspec of sqflite_darwin
dart run tool/validate_cocoapod.dart
```

Note: the tools call `flutter config --enable-swift-package-manager` (and
`validate_cocoapod.dart` `--no-enable-swift-package-manager`), a global
Flutter setting.
