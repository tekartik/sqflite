# sqflite ffi

[sqflite](https://pub.dev/packages/sqflite) based ffi implementation. Based on [`sqlite3`](https://pub.dev/packages/sqlite3). Thanks to [Simon Binder](https://github.com/simolus3)

It allows mocking sqflite during regular flutter unit test (i.e. not using the emulator/simulator).
One goal is make it stricter than sqflite to encourage good practices.

Currently supported on Linux, MacOS and Windows.

## Getting Started

### Dart

Add the following dev dependency:

```yaml
dev_dependencies:
  sqflite_common_ffi:
```

### Linux

`sqlite3` and `sqlite3-dev` linux packages are required.

One time setup for Ubuntu:

```bash
dart tool/linux_setup.dart
```

### MacOS

Should work as is.

### Windows

Should work as is (`sqlite3.dll` is bundled).

## Sample code

### Unit test code

`sqflite_ffi_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  test('simple sqflite example', () async {
    var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
}
```

### Application

Make it a normal dependency.

`main.dart`:
```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi;
  var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
  await db.execute('''
  CREATE TABLE Product (
      id INTEGER PRIMARY KEY,
      title TEXT
  )
  ''');
  await db.insert('Product', <String, dynamic>{'title': 'Product 1'});
  await db.insert('Product', <String, dynamic>{'title': 'Product 1'});

  var result = await db.query('Product');
  print(result);
  // prints [{id: 1, title: Product 1}, {id: 2, title: Product 1}]
  await db.close();
}
```

## Limitations

* Primary intent was to support unit testing sqflite based code but the implementation works on Windows/Mac/Linux flutter desktop application
* Database calls are made in a separate isolate,
* Multi-instance support (not common) is simulated