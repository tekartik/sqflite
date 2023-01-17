# sqflite_common_ffi_web

sqlite Web implementation (experimental). Features:
- Persistency (in indexeddb)
- Cross-tab safe (runs in a shared worker)

Thanks Simon Binder for the excellent sqlite3 lib.

## Setup

Add the dependency:
```yaml
  dependencies:
    sqflite_common_ffi_web: '>=0.1.0-dev.1'
```

### Setup binaries

Implementation requires sqlite3.wasm binaries into your web folder
as well as a sqflite specific shared worker.

You can install binaries using the command:

```bash
$ dart run sqflite_common_ffi_web:setup
```

It should create the following files in your web folder:
- `sqlite3.wasm`
- `sqflite_sw.js`

that you can put in source control or not (personally I don't)

### Use the proper factory.

```dart
// Use the ffi web factory in web apps (flutter or dart)
var factory = databaseFactoryFfiWeb;
var db = await factory.openDatabase('my_db.db');
var sqliteVersion = (await db.rawQuery('select sqlite_version()')).first.values.first;
print(sqliteVersion); // should print 3.39.3
```

## Limitations

### No shared worker available

When shared worker are not supported - for example in Android Chrome as of 2022-10-20 -, a basic web worker is used.
In this case it is not cross-tab safe.

## Status

This is still experimental:
- slow
- not fully tested
- bugs