# sqflite_darwin example

Apps normally depend on [sqflite](https://pub.dev/packages/sqflite), which
uses `sqflite_darwin` on iOS and macOS. Used directly, with the
`sqflite_common` API (`flutter pub add sqflite_darwin sqflite_common path`):

```dart
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // databaseFactory is set by SqfliteDarwin.registerWith() at startup.
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

The example app runs the sqflite example and test pages on the plugin. Its
platform folders are not checked in, create them first:

```sh
flutter create --platforms=macos,ios .
flutter run
```
