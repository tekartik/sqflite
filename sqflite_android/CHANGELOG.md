## 2.4.5

* Fix every later call hanging after a failed COMMIT or ROLLBACK (e.g. a deferred foreign key
  violation at commit): the transaction is ended, and rolled back if SQLite left it open.
* Fix an open lost (hang, or crash with several worker threads) when it follows a close that
  was not awaited.
* Use `propName = value` assignments in `android/build.gradle` (the space syntax is deprecated
  in Gradle 9 and removed in Gradle 10, #1217).
* Fix statements committed outside of any transaction after SQLite rolled back the transaction
  by itself (`ConflictAlgorithm.rollback`, `RAISE(ROLLBACK)`...): the transaction is now ended
  and the client marks it closed (requires sqflite_platform_interface 2.4.3).
* `execute` supports a `PRAGMA` returning a row (e.g. `PRAGMA journal_mode=WAL`, #929, #1176).

## 2.4.4+1

* Add `sqflite-android-setup` agent skill in `skills/`, installable with `dart run skills@ get`

## 2.4.3

* Updates minimum supported SDK version to Flutter 3.44 / Dart 3.12.
* Migrates to built-in Kotlin.

## 2.4.2+3

* Use compile statement for insert/update and delete to avoid invalid result in wal mode
* Requires dart 3.10

## 2.4.2+2

* Requires compile SDK 36
* Requires dart 3.9

## 2.4.1

* Requires dart 3.7

## 2.4.0

* Initial implementation from sqflite v2.3.3+2
