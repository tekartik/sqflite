## 2.4.4

* `readDatabaseBytes()` / `writeDatabaseBytes()` of the method channel
  factory resolve a relative path in the databases path, as `openDatabase()`
  (it was the current directory)
* A native `sqlite_error` without message gives a `DatabaseException` instead
  of a null check error
* Doc: README for implementers, example, dartdoc, skill

## 2.4.3

* Mark the transaction closed when the native error says SQLite rolled it back
  (`transactionClosed` in the error details, set by sqflite_android 2.4.5)

## 2.4.2

* Add `sqflite-platform-interface-implementers` agent skill in `skills/`, installable with `dart run skills@ get`

## 2.4.1

* Requires dart 3.12

## 2.4.0

* Initial implementation from sqflite v2.3.3+2