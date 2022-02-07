# Unit test

Currently testing using the package `test` or `flutter_test` is not supported. Testing using sqflite requires running
on a real supported platforms. That's unfortunately an issue for all plugins where mocking cannot easily be done.

Possible alternative (not as good though) are:

## Using flutter_driver

A solution is to use flutter driver. Look at the example app:

```bash
flutter driver --target=test_driver/main.dart
```

## Running as a regular application

Another option is to run the tests as a regular flutter application

```bash
flutter run test/my_sqflite_test.dart
```

## Using sqflite_common_ffi

This allow running unit tests using the desktop sqlite version installed. Be aware that the sqlite version used could be
different (and likely more recent).

Simple flutter test example:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
More info on [sqflite_common_ffi](https://github.com/tekartik/sqflite/tree/master/sqflite_common_ffi).

### Sqflite server

Some experiments are done using a [sqflite server](https://github.com/tekartik/sqflite_more/tree/master/sqflite_test)

### E2E

That seems to be the future solution for testing plugins and native code.
The example app also has a simple (and incomplete) e2e testing (could not really find a difference with flutter driver so far and the doc is not complete to allow iOS/Android and MacOS testing).
