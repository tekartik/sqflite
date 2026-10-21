# sqflite_example_android

Flutter project for running unit test on the device/emulator

The `android/` folder is not tracked, create it once (`--empty` skips the default
`test/widget_test.dart`, which does not compile here):

```bash
flutter create --platforms android --empty .
```

Run the `sqflite_common_test` tests on the Android plugin, results in the console:

```bash
flutter run -t lib/test_main.dart
```

Run the example app:

```bash
flutter run
```
