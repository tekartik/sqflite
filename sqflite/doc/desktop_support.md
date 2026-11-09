# Desktop support

`sqflite` only includes native Android, iOS and MacOS support. 

Desktop support is provided by [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi).
Since support is provided both on flutter and on DartVM on MacOS/Linux/Windows, it is not a flutter plugin.

## Setup

```bash
flutter pub add sqflite_common_ffi
```

Set the global factory once in `main()`, before opening any database. The rest
of your sqflite code (`openDatabase`, queries) stays the same.

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    // Windows specific setup, no-op elsewhere.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android, iOS and macOS keep the sqflite plugin.
  runApp(const MyApp());
}
```

Alternatively, the [`sqflite_ffi`](https://pub.dev/packages/sqflite_ffi) Flutter
package registers the ffi factory automatically on Windows and Linux (and on
the other platforms when the `sqflite` plugin is not used), no code needed.

For a web build too, see [one code base for mobile, desktop and web](../README.md#one-code-base-for-mobile-desktop-and-web).

## SQLite library

Since `sqflite_common_ffi` 2.4.0, [`package:sqlite3`](https://pub.dev/packages/sqlite3) 3.x
bundles a recent SQLite with the application using build hooks:
* Linux: nothing to install (`libsqlite3-dev` is only needed for
  `sqflite_common_ffi` < 2.4.0, or if you choose the system library).
* Windows: nothing to copy (`sqlite3.dll` is only needed for `sqflite_common_ffi` < 2.4.0).
* macOS: nothing to do.

Build hooks run with `flutter run`, `flutter build`, `flutter test`, `dart run` and
`dart test` (not with `dart file.dart`). The library (system SQLite, SQLCipher,
SQLite3MultipleCiphers...) can be chosen in `pubspec.yaml`, see
[sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi).

## Database location

With ffi, `getDatabasesPath()` returns `.dart_tool/sqflite_common_ffi/databases`
in the current directory. An installed application can be started from any
directory, so pick a folder of the application, typically with
[path_provider](https://pub.dev/packages/path_provider):

```dart
var dir = await getApplicationSupportDirectory();
await databaseFactory.setDatabasesPath(join(dir.path, 'databases'));
```

## Notes

* Database calls run in a background isolate.
* Encryption on desktop: see [encryption support](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/encryption_support.md).

See also some notes about how to keep you sqflite code as is and [supports Windows and Linux](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/using_ffi_instead_of_sqflite.md)
