# sqflite ffi

[sqflite](https://pub.dev/packages/sqflite) based ffi implementation. Based
on [`sqlite3`](https://pub.dev/packages/sqlite3). Thanks to [Simon Binder](https://github.com/simolus3)

* Works on Linux, MacOS and Windows on both Flutter and Dart VM.
* Works on iOS and Android (using [sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs) - Thanks
to [Simon Binder](https://github.com/simolus3))

It allows also mocking sqflite during regular flutter unit test (i.e. not using the emulator/simulator).

## Getting Started

### Dart

Add the following dev dependency:

```yaml
dev_dependencies:
  sqflite_common_ffi:
```

### Linux

`libsqlite3` and `libsqlite3-dev` linux packages are required.

One time setup for Ubuntu (to run as root):

```bash
dart tool/linux_setup.dart
```

or

```
sudo apt-get -y install libsqlite3-0 libsqlite3-dev
```

### MacOS

Should work as is.

### Windows

Should work as is in debug mode (`sqlite3.dll` is bundled).

In release mode,
add [sqlite3.dll](https://github.com/tekartik/sqflite/raw/master/sqflite_common_ffi/lib/src/windows/sqlite3.dll) in same
folder as your executable.

`sqfliteFfiInit` is provided as an implementation reference for loading the sqlite library. Please look
at [sqlite3](https://pub.dev/packages/sqlite3)
if you want to override the behavior.

### Web

Look at package [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web) for experimental Web support.

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

More info on unit testing [here](doc/testing.md)

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
  await db.insert('Product', <String, Object?>{'title': 'Product 1'});
  await db.insert('Product', <String, Object?>{'title': 'Product 1'});

  var result = await db.query('Product');
  print(result);
  // prints [{id: 1, title: Product 1}, {id: 2, title: Product 1}]
  await db.close();
}
```

Example with path_provider

```dart
import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

Future main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi;
  final io.Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  
  //Create path for database
  String dbPath = p.join(appDocumentsDir.path, "databases", "myDb.db");
  var db = await databaseFactory.openDatabase(
    dbPath,
  );

  await db.execute('''
  CREATE TABLE Product (
      id INTEGER PRIMARY KEY,
      title TEXT
  )
  ''');
  await db.insert('Product', <String, Object?>{'title': 'Product 1'});
  await db.insert('Product', <String, Object?>{'title': 'Product 1'});

  var result = await db.query('Product');
  print(result);
  // prints [{id: 1, title: Product 1}, {id: 2, title: Product 1}]
  await db.close();
}

```

If your existing application uses sqflite on iOS/Android/MacOS, you can also set the proper initialization to have
your
application [work on Linux and windows](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/using_ffi_instead_of_sqflite.md).

## Limitations

* Database calls are made in a separate isolate,
* Multi-instance support (not common) is simulated
* As another note, `getDatabasesPath()` has a lame implementation. You'd better rely on a custom strategy using
  package such as `path_provider`.
