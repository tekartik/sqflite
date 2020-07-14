Below are (or will be) personal recommendations on usage

## Single database connection

The API is largely inspired from Android ContentProvider where a typical SQLite implementation means
opening the database once on the first request and keeping it open.

Personally I have one global reference Database in my Flutter application to avoid lock issues. Opening the
database should be safe if called multiple times.

If you don't use `singleInstance`, keeping a reference (at the app level or in a widget) can cause issues with hot reload if the reference is lost (and the database not
closed yet).

## Isolates

Access should be done in the main isolate only.
* sqflite native access already happens in a background native thread
* Transaction mechanism is not cross-isolate safe
* [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) access is made in a separate isolate.

Some related discussions here:
* [Cannot access database instance from another Isolate](https://github.com/tekartik/sqflite/issues/186)
* [Problem tunning Sqflite in Isolate](https://github.com/tekartik/sqflite/issues/258)
* [Multi-Isolate access to Sqflite (iOS)](https://github.com/tekartik/sqflite/issues/168)
* [MissingPluginException when using sqflite via flutter_isolate](https://github.com/tekartik/sqflite/issues/169)

## Handling errors

Like any database, something wrong can happen when storing/reading data. Here are some information about [Handling errors and exceptions](handling_errors.md).