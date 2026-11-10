# sqflite test app (CocoaPods)

Test application of `sqflite_darwin` on iOS and macOS built with CocoaPods
(`disable-swift-package-manager: true` in `pubspec.yaml`). Its twin
`sqflite_test_app_darwin_spm` checks the Swift Package Manager build.

The `ios/` and `macos/` folders are not tracked, the tools create them:

```bash
# Create the iOS project and run it on the first iOS device or simulator
dart run tool/flutter_create_ios_and_run.dart
# Create the macOS project and run it
dart run tool/flutter_create_macos_and_run.dart
```

Note: the tools call `flutter config --no-enable-swift-package-manager`, a
global Flutter setting (the spm app's tools turn it on again).
