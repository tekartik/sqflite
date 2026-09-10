---
name: sqflite-android-setup
description: >-
  Use when configuring or troubleshooting the Android implementation of
  sqflite (package sqflite_android): when to add it explicitly, minSdk,
  SqfliteAndroid.registerWith, WAL via the com.tekartik.sqflite.wal_enabled
  manifest meta-data or setJournalMode, read-only opening and corruption
  handling, getDatabasesPath location, androidSetLocale / COLLATE LOCALIZED,
  the 1 MB CursorWindow row limit, background worker thread, Gradle/AGP build
  issues.
---

# sqflite_android: Android implementation of sqflite

`sqflite_android` is the endorsed Android implementation of the `sqflite`
federated plugin. Adding `sqflite` to a Flutter app pulls it in automatically
(`default_package: sqflite_android`); its `SqfliteAndroid.registerWith()`
installs the method channel `DatabaseFactory` as `databaseFactory` before
`main()` runs. It uses the SQLite shipped with the Android OS
(`android.database.sqlite`), so the SQLite version depends on the device.

```yaml
# pubspec.yaml (normal case): nothing Android specific
dependencies:
  sqflite:
```

## Guidelines

* Add `sqflite_android` explicitly only when the app does not depend on
  `sqflite` (for example it codes against `package:sqflite_common` and ships
  Android only). Then use `databaseFactory` / `openDatabase` from
  `package:sqflite_common/sqflite.dart`; no call is needed, registration is
  automatic. Android-only helpers such as `androidSetLocale` live in
  `package:sqflite/sqflite.dart`, not here.
* Requirements: `minSdk 19`, Java 17, Flutter >= 3.44 / Dart >= 3.12 (2.4.3
  uses the Kotlin built into the Flutter Gradle plugin, AGP 9). If the build
  fails with `androidJdkImage` or AGP errors, update the app's Gradle wrapper
  and `com.android.application` plugin versions.
* `getDatabasesPath()` returns `data/data/<package>/databases`; the plugin
  creates the parent directory of the path on open. A relative path is
  resolved there.
* SQL runs on a dedicated background worker thread (default
  `Process.THREAD_PRIORITY_DEFAULT`); calls are serialized per database.
* WAL is disabled by default. Enable it globally with
  `<meta-data android:name="com.tekartik.sqflite.wal_enabled"
  android:value="true"/>` inside `<application>` in
  `android/app/src/main/AndroidManifest.xml`, or per open with
  `db.setJournalMode('WAL')` in `onConfigure` (that extension falls back to
  `rawQuery` because `execute('PRAGMA journal_mode=WAL')` fails on Android
  when the manifest flag is not set).
* `readOnly: true` opens with `SQLiteDatabase.OPEN_READONLY` and a
  no-op corruption handler, so a corrupt or non-SQLite file is left intact
  and the first access fails. A read-write open uses Android's default
  handler which deletes a corrupt file.
* `db.androidSetLocale('fr-FR')` (extension `SqfliteDatabaseAndroidExt` in
  `package:sqflite/sqflite.dart`) sets the locale for `ORDER BY name COLLATE
  LOCALIZED`; call it in `onConfigure` at every open.
* Arguments are bound as strings; `SELECT ?1` returns `'3'` for `[3]`,
  comparisons and arithmetic still work.
* A single row must fit in the `CursorWindow` (about 1 MB):
  `SQLiteBlobTooBigException` / `Row too big to fit into CursorWindow` means
  a blob should live in a file. `java.lang.OutOfMemoryError` on writes: split
  into smaller transactions (for example 1000 operations each); reading:
  limit columns and rows.
* Inspect a device database from Android Studio: Device File Explorer,
  `data/data/<package>/databases`, Save As.
* `DatabaseException.getResultCode()` returns the extended SQLite code on
  Android (for example 2067 for a UNIQUE constraint), the primary code on
  iOS; handle both.
* `MissingPluginException` only in Android release mode: remove the
  `shrinkResources true` and `minifyEnabled true` lines from the app
  `build.gradle`.

## Examples

### Android-only app on the pure Dart API

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite_common:
  sqflite_android:
```

```dart
import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';

Future<Database> openAppDb() async {
  // databaseFactory was registered by SqfliteAndroid.registerWith().
  final path = join(await getDatabasesPath(), 'app.db');
  return openDatabase(
    path,
    version: 1,
    onConfigure: (db) => db.setJournalMode('WAL'),
    onCreate: (db, _) =>
        db.execute('CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)'),
  );
}
```

### Enabling WAL in the manifest

```xml
<application ...>
  <meta-data
      android:name="com.tekartik.sqflite.wal_enabled"
      android:value="true" />
</application>
```

### Localized sort (needs package:sqflite)

```dart
import 'package:sqflite/sqflite.dart';

Future<List<Map<String, Object?>>> sortedNames(String path) async {
  final db = await openDatabase(
    path,
    version: 1,
    onConfigure: (db) => db.androidSetLocale('zh-CN'),
    onCreate: (db, _) => db.execute('CREATE TABLE Test(name TEXT)'),
  );
  return db.query('Test', orderBy: 'name COLLATE LOCALIZED ASC');
}
```

## Common mistakes

* Adding both `sqflite` and `sqflite_android` to `pubspec.yaml`: harmless
  but redundant, `sqflite` already depends on it.
* Calling `execute('PRAGMA journal_mode=WAL')` and getting an error: use
  `setJournalMode('WAL')` or the manifest meta-data.
* Storing images or files as blobs and hitting the cursor window limit.
* Expecting JSON1 / UPSERT / `RETURNING` on old Android versions; check
  `SELECT sqlite_version()` or use `sqflite_common_ffi` for a bundled SQLite.

## More

App-level API: the `sqflite` package skills (`sqflite-open-database`,
`sqflite-crud-and-transactions`, `sqflite-testing-and-platforms`). Other
implementation: `sqflite_darwin`. Interface: `sqflite_platform_interface`.
