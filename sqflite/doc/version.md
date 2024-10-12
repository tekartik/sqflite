# SQLite version

`sqflite` uses the SQLite available on the platform. It does not ship/bundle any additional SQLite library. You can get the
version using `SELECT sqlite_version()`:

```dart
print((await db.rawQuery('SELECT sqlite_version()')).first.values.first);
```

which should give a version formatted like this:

```
3.22.0
```

Unfortunately the version of SQLite depends on the OS version as sqflite
uses the SQLite version available on the platform.

Some features may not be available depending on the SQLite version.
For example `UPSERT` statement (`INSERT INTO ..... ON CONFLICT UPDATE SET`) is only available starting from SQLite 3.24.0 so
is not available on iOS 11.0 or android 10 (API Level 29).
Check the [SQLite documentation](https://www.sqlite.org/lang_UPSERT.html) for more information on this topic.

And check the available SQLite version on the platform you are targeting.

You could get a more recent version using [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi).

You could then add [`sqlite3_flutter_libs`](https://pub.dev/packages/sqlite3_flutter_libs) for ios/android or include your own
sqlite shared library for desktop or mobile (one for each platform).

## Android

See https://developer.android.com/reference/android/database/sqlite/package-summary

| Android API | SQLite Version |
|-------------|----------------|
|      API 27 |           3.19 |
|      API 26 |           3.18 |
|      API 24 |            3.9 |
|      API 21 |            3.8 |
|      API 11 |            3.7 |


## iOS

See https://github.com/yapstudios/YapDatabase/wiki/SQLite-version-(bundled-with-OS)

| iOS Version | SQLite Version |
|-------------|----------------|
|      13.1.3 |         3.28.0 |
|        12.1 |         3.24.0 |
|        11.0 |         3.19.3 |
|      10.3.1 |         3.16.0 |
|       9.3.1 |       3.8.10.2 |
|         8.2 |          3.8.5 |


## Mac OS


| MacOS Version | SQLite Version |
|---------------|----------------|
|       10.14.2 |         3.24.0 |
