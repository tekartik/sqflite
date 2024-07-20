Below are (or will be) personal recommendations on usage

## Single database connection

The API is largely inspired from Android ContentProvider where a typical SQLite implementation means
opening the database once on the first request and keeping it open.

Personally I have one global reference Database in my Flutter application to avoid lock issues. Opening the
database should be safe if called multiple times.

If you don't use `singleInstance`, keeping a reference (at the app level or in a widget) can cause issues with hot reload if the reference is lost (and the database not
closed yet).

## Isolates

Access *should* be done in the main isolate:
* sqflite native access already happens in a background native thread
* Transaction mechanism is not cross-isolate safe
* [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) access is made in a separate isolate.

Many people have asked about access from another isolate and unfortunately I don't have a good answer for that.
It **should** work although I have not tested it much and I have avoided it (for example by saving the temporary data read
in a file that I handle later in the main isolate). One common usage
on Android and iOS is to have access from a push notification isolate or scheduled task.
* Good if you can avoid it and only limit to this case (background notification / scheduled task)
* In both isolates
  * Use `singleInstance: false` in `openDatabase`
  * Don't close the database
* Since hot reload might fail when using `singleInstance: false` (if done while a transaction is in progress), you 
  can try `singleInstance: true` in the main isolate only.

Some related discussions here:
* [Cannot access database instance from another Isolate](https://github.com/tekartik/sqflite/issues/186)
* [Problem tunning Sqflite in Isolate](https://github.com/tekartik/sqflite/issues/258)
* [Multi-Isolate access to Sqflite (iOS)](https://github.com/tekartik/sqflite/issues/168)
* [MissingPluginException when using sqflite via flutter_isolate](https://github.com/tekartik/sqflite/issues/169)
* [Accessing database from a background Isolate & main Isolate](https://github.com/tekartik/sqflite/issues/1118)

## Batch vs Transaction

There is always a confusion between the 2 notions, although they have a different purpose:

Transaction:
- A transaction is a SQLite concept (`BEGIN TRANSACTION`, `COMMIT`). In a transaction, you run SQL statements
 as you would do normally (i.e. you await each statement) but the changes are only effective on COMMIT
- A transaction is committed if the callback does not throw an error. If an error is thrown,
  the transaction is cancelled. So to rollback a transaction one way is to throw an exception.

Batch
- A batch is just a list of statement to execute all at once
- A batch on a database is run in a transaction (a transaction is created for you)
- A batch in a transaction is committed when the transaction terminates
- You can create/commit mutiple batches in a transaction however the changes are committed *for real* only when the transaction terminates (and a failure would rollback all batches)

Prefer:
- A batch if you have a list statements to execute in sequence and no query on which your behavior depends on
- Use transaction for upsert like scenario or if you want to check a query result before an insert/update or delete.
- You can use them together (i.e. a batch in a transaction.)
 
## Handling errors

Like any database, something wrong can happen when storing/reading data. Here are some information about [Handling errors and exceptions](handling_errors.md).