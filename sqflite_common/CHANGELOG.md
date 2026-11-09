## 2.5.16

* Fix the single instance cache: closing an already closed database no longer
  drops a newer instance opened at the same path, and after an
  `onDatabaseDowngradeDelete` open or a `deleteDatabase` through
  `SqfliteDatabaseFactoryLogger`, `openDatabase` no longer returns a second (or
  the deleted) instance
* `Batch.apply()` in `onCreate`/`onUpgrade`/`onDowngrade` runs in the open
  transaction instead of hanging
* `openDatabase` no longer modifies the given `OpenDatabaseOptions` (options with
  `onDatabaseDowngradeDelete` can be reused)
* `DatabaseException.getResultCode()` returns null instead of throwing when the
  exception has no message

## 2.5.15

* Fix every later call hanging after a failed `COMMIT` of a transaction or a batch
  (`SQLITE_BUSY` while another connection reads the database, deferred foreign key
  violation...), seen with `sqflite_common_ffi`: the transaction left open by SQLite
  is now rolled back before the error is thrown
  (#1219, thanks to PolynomialDivision).

## 2.5.14

* Fix hang when closing a query cursor before its end inside a transaction
  (`sqflite_common_ffi`, Android)
* `Batch.apply()` on a closed database fails with a `database_closed` error, like
  `Batch.commit()`
* Debug argument check (once per type warning) also done for `rawInsert` (and `insert`)
  and the batch raw methods, like `rawQuery`, `rawUpdate` and `rawDelete`

## 2.5.13+1

* Fix web detection (`kSqfliteIsWeb`) when compiled with dart2wasm: database paths were
  rewritten as absolute urls, which broke `databaseExists`, `deleteDatabase`,
  `readDatabaseBytes` and `writeDatabaseBytes` in `sqflite_common_ffi_web`
* Allow general read access to `databaseFactoryOrNull`.

## 2.5.12

* Add `sqflite-common-api` agent skill in `skills/`, installable with `dart run skills@ get`

## 2.5.11

* Add `sandbox()` extension method on `DatabaseFactory` to create a factory
  where every database is located below a root path

## 2.5.10+1

* Add `options` to `openDatabase`

## 2.5.9

* Requires dart 3.12

## 2.5.8

* Add `rollbackActiveTransactionOnOpen` open options for native implementation when using singleInstance.
  in release mode by default it will no more rollback active transactions on opening the DB

## 2.5.7

* Add `iterate` method and export `SqfliteSqlCommand` and extension helpers

## 2.5.6+1

* Requires dart 3.10

## 2.5.6

* Add `Database.setJournalMode` extension helper method.
* Requires dart 3.8

## 2.5.5

* Requires dart 3.7

## 2.5.4+6

* Remove dependency on `dart:html`
* Add more keywords to escape from sqlite.org
* Export deprecated `SqfliteOptions` in sqflite_dev

## 2.5.3

* Export `databaseId` and `transactionId` in logger events.

## 2.5.2-1

* Start support for rolled back transaction by an inner statement.

## 2.5.1-2

* Add `readTransaction` support to `Database` to allow concurrent read-only transactions (sqlite_async only)
 
## 2.5.0+2

* Dart 3 only
* Add `readDatabaseBytes` and `writeDatabaseBytes` factory methods.

## 2.4.5+1

* Add global API from sqflite (openDatabase, deleteDatabase, databaseFactory...) from sqflite
* Fixes SqlBuilder for query with offset without limit.

## 2.4.4

* Dart 3 support

## 2.4.3

* add minimum support for SQLite uri (https://www.sqlite.org/uri.html)

## 2.4.2+2

* add experimental logger support.

## 2.4.1

* add support for `Batch.length` to help finding the last added operation index.
* strict-casts and sdk 2.18 support

## 2.4.0+2

* add support for `Database.queryCursor()` and `Database.rawQueryCursor()`
* base experimental web support
* Support for transaction v2

## 2.3.0

- Add `apply()` method to `Batch`. It will execute statements in that batch
  without starting a new transaction.

## 2.2.1+1

* Add debug tag to database factory

## 2.2.0

* Export `Object? result` in `DatabaseException`
* Export deprecated `DatabaseFactory.debugSetLogLevel` for quick logging.

## 2.1.0

* Requires dart sdk 2.15

## 2.0.1+1

* Truncate arguments in exception

## 2.0.0+2

* `nnbd` support
* Fix transaction ref counting on begin transaction failure

## 1.0.3+2

* Don't lock globally during open but lock per database full path.
 
## 1.0.2+1

* Don't create a transaction during openDatabase if not needed.

## 1.0.1

* Export `DatabaseException.getResultCode()`.

## 1.0.0+1

* Initial revision from sqflite 1.2.2+1
