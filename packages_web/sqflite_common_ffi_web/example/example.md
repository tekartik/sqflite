# sqflite_common_ffi_web example

## Setup

From the project folder (the one containing the `web` folder):

```bash
dart pub add sqflite_common_ffi_web sqflite_common
# Creates web/sqlite3.wasm and web/sqflite_sw.js, run it again after upgrades
dart run sqflite_common_ffi_web:setup
```

## Dart web app

`web/main.dart` (loaded by `web/index.html` as `main.dart.js`, for example with
`webdev serve`):

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  var factory = databaseFactoryFfiWeb;
  // On the web, the path is only a name.
  var db = await factory.openDatabase(
    'notes.db',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Note (id INTEGER PRIMARY KEY, content TEXT NOT NULL)',
        );
      },
    ),
  );
  await db.insert('Note', {'content': 'Note ${DateTime.now()}'});
  var rows = await db.query('Note');
  // The notes are kept in the browser storage: one more at each reload.
  print('Notes: ${rows.length}'); // in the browser console
  await db.close();
}
```

## Flutter app

Set the global factory once in `main()`, the rest of the `sqflite` code is the
same as on mobile:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  var db = await openDatabase(
    'notes.db', // a name on the web, relative to getDatabasesPath() on mobile
    version: 1,
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE Note (id INTEGER PRIMARY KEY, content TEXT NOT NULL)',
      );
    },
  );
  await db.insert('Note', {'content': 'Hello'});
  runApp(const SizedBox());
}
```

Run it on a fixed port to keep the same browser storage between runs:
`flutter run -d chrome --web-port 8080`.

For Windows and Linux too, see
[one code base for mobile, desktop and web](https://github.com/tekartik/sqflite/blob/master/sqflite/README.md#one-code-base-for-mobile-desktop-and-web).
