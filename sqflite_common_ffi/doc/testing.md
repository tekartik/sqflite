## Unit testing `sqflite` code using `sqflite_common_ffi`

Currently regular flutter test cannot run for plugins. One solution is to use
`integration_test` to run UI test on the device.

An alternative solution is to use `sqflite_common_ffi` since it allows running SQLite code on 
the desktop (MacOS/Windows/Linux).

### Setup

Include `sqflite_common_ffi` as a `dev_dependency` in `pubspec.yaml`:

```yaml
dev_dependency:
  sqflite_common_ffi:
```

### Writing unit test for flutter

In order to use your existing `sqflite` code in flutter test, you have to [setup `sqflite_common_ffi` to replace the global default flutter database factory](../doc/using_ffi_instead_of_sqflite.md).

This can be done in a `setUpAll` method like this:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

Future main() async {
  // Setup sqflite_common_ffi for flutter test
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  });
  test('Simple test', () async {
    var db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, version) async {
      await db
          .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
    });
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});
    // Check content
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'}
    ]);

    await db.close();
  });
}
```


### Writing unit test for Dart VM

You can also write regular dart test. Instead of using `openDatabase` (which is flutter only) you have use
the proper `SqfliteDatabaseFactory` to open a database:

```dart
@TestOn('vm')
library sqflite_common_ffi.test.sqflite_ffi_doc_test;

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  test('Simple test', () async {
    var factory = databaseFactoryFfi;
    var db = await factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
            }));
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    // Check content
    expect(await db.query('Test'), [{'id': 1, 'value': 'my_value'}]);

    await db.close();
  });
}
```

### Writing widget test

There seems to be several restrictions in widget test. One solution here is to use the ffi implementation
without isolate:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize ffi implementation
  sqfliteFfiInit();
  // Set global factory, do not use isolate here
  databaseFactory = databaseFactoryFfiNoIsolate;

  testWidgets('Test sqflite database', (WidgetTester tester) async {
    var db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, version) async {
      await db
          .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
    });
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    // Check content
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'}
    ]);

    await db.close();
  });
}
```