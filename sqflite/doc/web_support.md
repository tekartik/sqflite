# Web support

There is an experimental Web support using [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web).
SQLite runs as WebAssembly (`sqlite3.wasm`) in a shared worker and the databases
are stored in the browser (IndexedDB).

## Setup

```bash
flutter pub add sqflite_common_ffi_web
# Creates web/sqlite3.wasm and web/sqflite_sw.js
dart run sqflite_common_ffi_web:setup
```

Run the setup command again (with `--force`) after upgrading
`sqflite_common_ffi_web`. Without these 2 files, the first database call fails.

Set the global factory once in `main()`, before opening any database:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const MyApp());
}
```

For desktop too, see [one code base for mobile, desktop and web](../README.md#one-code-base-for-mobile-desktop-and-web).

## Limits

* A database path is a name (`my_db.db`), there is no file system. Use
  `databaseFactory.readDatabaseBytes()` / `writeDatabaseBytes()` to export or
  import a database, see [opening an asset database on the web](https://github.com/tekartik/sqflite/blob/master/packages_web/sqflite_common_ffi_web/doc/opening_asset_db_web.md).
* The storage is tied to the origin, including the port: use the same port when
  debugging (`flutter run -d chrome --web-port 8080`).
* `singleInstance: false` is not supported for a database file (`ArgumentError`).
* Without shared worker support (Android Chrome), a basic web worker is used:
  not safe when several tabs use the same database.
* Slower than native, experimental.

More information in [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web).
