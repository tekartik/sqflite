## 1.0.2

* Add `sqflite-common-ffi-async-factory` agent skill in `skills/`, installable with `dart run skills@ get`

## 1.0.1

* Fix hang when accessing a database after `close()` (database now properly reports `database_closed` error)

## 1.0.0

* Requires dart 3.12

## 0.2.0

* Requires `sqlite_async: ^0.14.0`
* Requires dart 3.11
* supports sqlite3 v3

## 0.1.4+1

* Requires dart 3.10
* sqflite_async "<0.14.0"

## 0.1.4

* Requires dart 3.7

## 0.1.3+1

* Remove dependency on `dart:html`

## 0.1.2

* `sqflite3: >= 2.3.0`
* Supports transaction rolled back by an inner statement.

## 0.1.1+2

- Allow concurrent read.

## 0.1.0

- Initial version.
