# sqflite_darwin

[![pub package](https://img.shields.io/pub/v/sqflite_darwin.svg)](https://pub.dev/packages/sqflite_darwin)

The iOS and macOS implementation of the [sqflite](https://pub.dev/packages/sqflite)
plugin: the SQLite of the OS through a bundled copy of
[FMDB](darwin/README.md), with the sqflite API (`openDatabase`, `Database`,
`Transaction`, `Batch`...).

## Getting started

Most apps do not add this package: `sqflite` depends on it and Flutter uses it
on iOS and macOS automatically (endorsed implementation).

```sh
flutter pub add sqflite
```

Then follow the [sqflite README](https://pub.dev/packages/sqflite).

Add `sqflite_darwin` yourself only for an iOS/macOS only app that codes
against the `sqflite_common` API without depending on `sqflite`:

```sh
flutter pub add sqflite_darwin sqflite_common path
```

Nothing to call: at startup `SqfliteDarwin.registerWith()` sets the global
`databaseFactory` (unless another factory is already set).

```dart
import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';

Future<Database> openAppDatabase() async {
  // The Documents directory of the app
  var path = join(await getDatabasesPath(), 'app.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) =>
        db.execute('CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)'),
  );
}
```

`SqfliteDarwin.createUnprotectedFolder()` is in `package:sqflite`.

## Platforms and requirements

* iOS 12.0+ and macOS 10.14+ (one Objective-C source tree), Flutter >= 3.44,
  Dart >= 3.12.
* CocoaPods and Swift Package Manager both work. No `FMDB` pod is used: remove
  any `pod 'FMDB'` left in a `Podfile`, then `flutter clean` and delete
  `Podfile.lock`.
* The SQLite version is the one of the OS (`SELECT sqlite_version()`). For a
  bundled SQLite use [sqflite_ffi](https://pub.dev/packages/sqflite_ffi).

## What is specific to iOS and macOS

* `getDatabasesPath()` is the Documents directory: visible in the Files app
  and backed up on iOS, `~/Documents` for a macOS app that is not sandboxed.
  Use [path_provider](https://pub.dev/packages/path_provider) (for example
  `getApplicationSupportDirectory()`) for data the user should not see.
* The parent directory is created on a read-write open, not on a read-only
  one (that fails when the file does not exist).
* `deleteDatabase(path)` also deletes the `-wal`, `-shm` and `-journal` files.
* The calls of a database run in order on a background queue. On macOS the
  results come back on the main thread.
* `getResultCode()` of a `DatabaseException` is the extended SQLite code (2067
  for a UNIQUE constraint), as on the other platforms.
* Files of a protected folder cannot be read while an iOS device is locked
  (background tasks): create the database in a folder made with
  `SqfliteDarwin.createUnprotectedFolder(parent, name)` (non sensitive data
  only).

## Common pitfalls

* Arguments: only `null`, `num`, `String` and `Uint8List` (blob) are
  supported.
* Build errors on an old project: set `IPHONEOS_DEPLOYMENT_TARGET` (>= 12.0)
  in the `Podfile` `post_install`, or recreate the `ios/` folder with
  `flutter create .`.

## More

* [sqflite documentation](https://github.com/tekartik/sqflite/tree/master/sqflite/doc)
  (opening, transactions, errors, troubleshooting).
* Agent skill: [`sqflite-darwin-setup`](skills/sqflite-darwin-setup/SKILL.md).
* Other implementations: [sqflite_android](https://pub.dev/packages/sqflite_android),
  [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) (desktop,
  tests). Interface for implementers:
  [sqflite_platform_interface](https://pub.dev/packages/sqflite_platform_interface).
