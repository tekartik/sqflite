# Unit test

The `sqflite` plugin needs a real Android, iOS or macOS device or simulator: it
does not run in `flutter test` (`openDatabase` throws `Bad state: databaseFactory
not initialized`). To run your sqflite code in unit tests, use
`sqflite_common_ffi`: same API, running SQLite on the desktop (Linux, macOS,
Windows, also on CI).

To test on the device itself, use integration tests (see below).

## Using sqflite_common_ffi

This allow running unit tests using the desktop sqlite version bundled by
`sqflite_common_ffi`. Be aware that the sqlite version used could be different
(and likely more recent) than the one of the device.

Add it as a dev dependency:

```bash
flutter pub add dev:sqflite_common_ffi
```

Simple flutter test example:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

/// Initialize sqflite for test.
void sqfliteTestInit() {
  // Initialize ffi implementation
  sqfliteFfiInit();
  // Set global factory
  databaseFactory = databaseFactoryFfi;
}

Future main() async {
  sqfliteTestInit();
  test('simple', () async {
    var db = await openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE Product (
        id INTEGER PRIMARY KEY,
        title TEXT
      )
  ''');
    await db.insert('Product', <String, Object?>{'title': 'Product 1'});
    await db.insert('Product', <String, Object?>{'title': 'Product 2'});

    var result = await db.query('Product');
    expect(result, [
      {'id': 1, 'title': 'Product 1'},
      {'id': 2, 'title': 'Product 2'}
    ]);
    await db.close();
  });
}
```

Close the database at the end of each test: while it is open,
`openDatabase(inMemoryDatabasePath)` returns the same in-memory database (single
instance). After a close, the next open gives a new empty database. For file
databases, call `deleteDatabase(path)` before the test.

More info on [sqflite_common_ffi](https://github.com/tekartik/sqflite/tree/master/sqflite_common_ffi).

### Writing widget test

There seems to be several restrictions in widget test. One solution here is to use the ffi implementation
without isolate:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfiNoIsolate, sqfliteFfiInit;

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

## Testing on a device

Use [integration tests](https://docs.flutter.dev/testing/integration-tests)
to run your code with the `sqflite` plugin on a device or simulator. The
[example app](../example) of this package runs its tests this way:

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/sqflite_test.dart
```
