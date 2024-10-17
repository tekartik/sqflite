## 2.3.4

* Improve sqlite3.dll finder on windows
 
## 2.3.3+2

* Remove dependency on `dart:html`.

## 2.3.2+1

* `sqflite3: >= 2.3.0`
* Supports transaction rolled back by an inner statement.

## 2.3.1

* `sqflite3: >= 2.2.0`
* `sdk: >= 3.2.0`

## 2.3.0+4

* Support `PRAGMA sqflite -- db_config_defensive_off`
* Dart 3 only.
* Bundle Windows sqlite3.dll 3.42.0

## 2.2.5

* Export global sqflite API

## 2.2.4

* Dart 3 support

## 2.2.3

* Depends on sqlite3 >= 1.11.0

## 2.2.2

* add minimum support for SQLite uri (https://www.sqlite.org/uri.html)

## 2.2.1+1

* strict-casts and sdk 2.18 support

## 2.2.0+1

* Implements `Database.queryCursor()` and `Database.rawQueryCursor()`
* base for experimental web support
* Support for transaction v2

## 2.1.1

* Windows binary 3.38.2

## 2.1.0+2

* Add `databaseFactoryFfiNoIsolate`
* Fix windows release mode for basic ffi setup

## 2.0.0+3

* `nnbd` support
* Improved sqlite shared lib loading mechanism to support alternate library.

## 1.1.1+3

* Fixes hot-restart lock issue
* Fixes missing `databaseExists` handler
* Don't load bundled sqlite3.dll on windows release mode.

## 1.1.0+1

* Use `sqlite3` instead of `moor_ffi`

## 1.0.0+4

* Support extended result code exception

## 1.0.0+1

* Initial revision from sqflite_ffi_test experimentation
