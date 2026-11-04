## 2.4.5

* Fix every later call hanging after a failed COMMIT or ROLLBACK (e.g. a deferred foreign key
  violation at commit): the transaction is ended, and rolled back if SQLite left it open.
* Fix statements committed outside of any transaction after SQLite rolled back the transaction
  by itself (`ConflictAlgorithm.rollback`, `RAISE(ROLLBACK)`...): the transaction is now ended
  and the client marks it closed (requires sqflite 2.4.5 or sqflite_platform_interface 2.4.3).
* `execute` supports a statement returning a row (e.g. `PRAGMA journal_mode = WAL`, #929, #1176).
* Fix calls on a database possibly run out of order (e.g. transaction calls not awaited): they now
  go through a serial queue per database, as do the first setup call after open and the close.

## 2.4.4+1

* Add `sqflite-darwin-setup` agent skill in `skills/`, installable with `dart run skills@ get`

## 2.4.3+1

* Minor SPM support update

## 2.4.3

* Requires dart 3.12

## 2.4.2

* Requires dart 3.7

## 2.4.1+1

* Allow creating unprotected folder in iOS (issue #924)
  * Fix delete database to properly delete all related files (`-shm`, `-wal`, `-journal`)

## 2.4.1-1

* Add Swift Package Manager support

## 2.4.0-0

* Initial implementation from sqflite v2.3.3+2
