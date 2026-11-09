# sqflite_android example

Apps normally depend on [sqflite](https://pub.dev/packages/sqflite), which
uses `sqflite_android` on Android. Used directly, with the `sqflite_common`
API (`flutter pub add sqflite_android sqflite_common path`):

```dart
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // databaseFactory is set by SqfliteAndroid.registerWith() at startup.
  var db = await openDatabase(
    join(await getDatabasesPath(), 'example.db'),
    version: 1,
    onCreate: (db, version) =>
        db.execute('CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)'),
  );
  await db.insert('Item', {'name': 'one'});
  print(await db.query('Item')); // [{id: 1, name: one}]
  await db.close();
}
```

## This folder

The example app runs the sqflite example and test pages on the plugin:

```sh
flutter run
```

Native tests of the plugin (from `android/`, after `flutter pub get`):

```sh
cd android
# Java unit tests of the plugin
./gradlew :sqflite_android:test
# Instrumented tests, with an emulator or a device connected
./gradlew connectedAndroidTest
```

`dart run tool/run_android_native_test.dart` runs both.
