Below are (or will be) personal recommendations on usage

## Single database connection

The API is largely inspired from Android ContentProvider where a typical SQLite implementation means
opening the database once on the first request and keeping it open.

Personally I have one global reference Database in my Flutter application to avoid lock issues. Opening the
database should be safe if called multiple times.

If you don't use `singleInstance`, keeping a reference (at the app level or in a widget) can cause issues with hot reload if the reference is lost (and the database not
closed yet).

## Handling errors

Like any database, something wrong can happen when storing/reading data. Here are some information about [Handling errors and exceptions](handling_errors.md).