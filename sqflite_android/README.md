# sqflite_android

[![pub package](https://img.shields.io/pub/v/sqflite_android.svg)](https://pub.dev/packages/sqflite_android)

The Android implementation of the [sqflite](https://pub.dev/packages/sqflite)
plugin: SQLite through the Android SDK (`android.database.sqlite`), with the
sqflite API (`openDatabase`, `Database`, `Transaction`, `Batch`...).

## Getting started

Most apps do not add this package: `sqflite` depends on it and Flutter uses it
on Android automatically (endorsed implementation).

```sh
flutter pub add sqflite
```

Then follow the [sqflite README](https://pub.dev/packages/sqflite).

Add `sqflite_android` yourself only for an Android only app that codes against
the `sqflite_common` API without depending on `sqflite`:

```sh
flutter pub add sqflite_android sqflite_common path
```

Nothing to call: at startup `SqfliteAndroid.registerWith()` sets the global
`databaseFactory` (unless another factory is already set).

```dart
import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';

Future<Database> openAppDatabase() async {
  // /data/user/0/<package>/databases/app.db
  var path = join(await getDatabasesPath(), 'app.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) =>
        db.execute('CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)'),
  );
}
```

Android only helpers (`androidSetLocale`) are in `package:sqflite`.

## Platform and requirements

* Android only (`minSdk 19`), Flutter >= 3.44, Dart >= 3.12, Java 17.
* The SQLite version is the one of the device (`SELECT sqlite_version()`):
  recent features (`RETURNING`, JSON functions...) need a recent Android. For
  a bundled SQLite use [sqflite_ffi](https://pub.dev/packages/sqflite_ffi).

## What is specific to Android

* `getDatabasesPath()` is `/data/user/0/<package>/databases` (or
  `/data/data/<package>/databases`). The parent directory of a database is
  created on open.
* The calls run on one background thread, in order for each database.
* WAL is off by default. Turn it on in `onConfigure` with
  `await db.setJournalMode('WAL')`, or for every database with this meta-data
  in `<application>` of `android/app/src/main/AndroidManifest.xml`:
  `<meta-data android:name="com.tekartik.sqflite.wal_enabled" android:value="true" />`.
* A read-write open of a corrupt file deletes it (Android default handler); a
  `readOnly: true` open keeps it and fails on the first access.
* An insert ignored by a conflict (`ConflictAlgorithm.ignore`) returns -1
  (0 on the other platforms). Test `id <= 0`.
* `getResultCode()` of a `DatabaseException` is the extended SQLite code (2067
  for a UNIQUE constraint), as on the other platforms.
* `file:` uris are not supported: pass a file path.

## Common pitfalls

* Arguments: only `null`, `num`, `String` and `Uint8List` (blob) are
  supported. Other typed lists (`Int32List`...) are stored as text by an
  insert or an update and rejected by a query.
* A row must fit in the Android cursor window (around 1 to 2 MB): keep big
  blobs in files (`Row too big to fit into CursorWindow`).
* `MissingPluginException` in release mode only: check the app R8/ProGuard
  settings (`minifyEnabled`, `shrinkResources`).

## More

* [sqflite documentation](https://github.com/tekartik/sqflite/tree/master/sqflite/doc)
  (opening, transactions, errors, troubleshooting).
* Agent skill: [`sqflite-android-setup`](skills/sqflite-android-setup/SKILL.md).
* Other implementations: [sqflite_darwin](https://pub.dev/packages/sqflite_darwin)
  (iOS, macOS), [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi)
  (desktop, tests). Interface for implementers:
  [sqflite_platform_interface](https://pub.dev/packages/sqflite_platform_interface).
