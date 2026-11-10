## 1.2.2

* dart2wasm: an int beyond 2^53 sent to the web worker is no longer rounded

## 1.2.1

* `x.db`, `./x.db` and `/x.db` are the same database: they opened two connections on the same
  file (a write could be lost) and `deleteDatabase` by a relative name did not close the open
  database. `db.path` is the resolved path (`/x.db`).
* Worker: `sqlite3.wasm` is loaded once when the first calls arrive together, and a load error
  (missing or wrong `sqlite3.wasm`) is the error of the call (it was a `null` result).
* `SqfliteFfiWebOptions(inMemory: true)` keeps the databases in memory (it was ignored).
* `setup --sqlite3-wasm-url` and `SqfliteWebSetupOptions.sqlite3WasmUri` are used (they were
  ignored).
* The io stubs say the factories are web only.
* Doc: README (getting started, setup options, common mistakes), skills, dartdoc.
* Requires sqflite_common_ffi 2.4.6. Run `dart run sqflite_common_ffi_web:setup` after upgrading:
  the worker gets these fixes and the sqflite_common_ffi 2.4.6 ones (batch rollback error, cursor
  released on close).

## 1.2.0+1

* Doc: README, example tab, `databaseFactoryFfiWeb` dartdoc
* Fix `deleteDatabase`, `databaseExists`, `readDatabaseBytes` and `writeDatabaseBytes` when the
  application is compiled with dart2wasm (`flutter build web --wasm`): paths are now resolved the way
  sqlite does (requires `sqflite_common` 2.5.13, web detection was wrong with dart2wasm)
* Update sqlite3 wasm build to 3.6.0
* `openDatabase` throws an `ArgumentError` when `singleInstance` is false for a persistent database:
  multiple connections to the same database file are not supported on the web (no locking between
  connections in the virtual file system, which could corrupt the database).

## 1.1.3

* Add `sqflite-common-ffi-web-options` and `sqflite-common-ffi-web-setup` agent skills in `skills/`, installable with `dart run skills@ get`

## 1.1.2

* Requires dart 3.12

## 1.1.1

* Update sqlite3 wasm build to 3.1.2
* Fix wasm and indexed db name overriding in shared worker mode

## 1.1.0

* sqlite ^3.1.0 (deps and wasm build)
* Requires dart 3.9

## 1.0.2

* sqlite ^2.9.4 (deps and wasm build)

## 1.0.1+2

* Requires dart 3.9
* Bump sqlite3 wasm build to 2.9.3

## 1.0.1+1

* Requires dart 3.8
* Bump sqlite3 wasm build to 2.8.0

## 1.0.0

* Requires dart 3.7
* Bump sqlite3 wasm build to 2.7.3

## 0.4.5+4

* Setup for sqlite3 2.3.6
* Improved Wasm support
* Mark it wasm ready for pub.dev

## 0.4.3+2

* Remove dependency on `dart:html`. Requires rebuilding the worker file.

## 0.4.2+3

* Setup for sqlite3 2.3.0

## 0.4.2+2

* Use local webdev dependency during setup.
* Setup for sqlite3 2.2.0
* Remove `io` dependency
* requires sdk 3.2.0

## 0.4.1

* Use `dev_build` dependency instead of `dev_test`

## 0.4.0

* dart 3 only

## 0.3.6

* sqlite3 2.0.0

## 0.3.5+1

* Dart 3 support
* sqlite3 1.11.1

## 0.3.4

* Depends on sqlite3 >= 1.11.0
* Bump sqlite3 wasm version

## 0.3.3+3

* Bump sqlite3 wasm version
* Report initialization error (missing worker file).

## 0.3.2

* strict-casts and sdk 2.18 support

## 0.3.1

- Support for transaction v2 and cross tab safety

## 0.3.0

- Use (basic) worker if shared worker is not available (android chrome for example)

## 0.2.0+1

- Initial version using shared worker
