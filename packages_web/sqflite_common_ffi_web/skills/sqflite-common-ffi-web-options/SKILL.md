---
name: sqflite-common-ffi-web-options
description: >-
  Use when customizing or debugging sqflite on the web with
  package:sqflite_common_ffi_web beyond the default factory:
  createDatabaseFactoryFfiWeb, SqfliteFfiWebOptions (sqlite3WasmUri,
  sharedWorkerUri, indexedDbName, inMemory, forceAsBasicWorker), serving
  sqlite3.wasm and sqflite_sw.js from another location or name, the
  sw_js_file pubspec override, several isolated IndexedDB stores,
  sqfliteFfiWebLoadSqlite3Wasm and sqfliteFfiWebStartSharedWorker,
  SqfliteFfiWebContext, sqliteFfiWebDebugWebWorker, and inspecting the worker
  in Chrome (chrome://inspect/#workers).
---

# sqflite_common_ffi_web: custom factories, options and debugging

The default `databaseFactoryFfiWeb` loads `sqflite_sw.js` and `sqlite3.wasm`
relative to the page and stores everything in the IndexedDB database
`sqflite_databases`. `createDatabaseFactoryFfiWeb` builds a factory with other
locations, another store name or no worker. Basic setup is covered by
`sqflite-common-ffi-web-setup`.

```dart
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

final databaseFactoryCustomWeb = createDatabaseFactoryFfiWeb(
  options: SqfliteFfiWebOptions(
    sharedWorkerUri: Uri.parse('/assets/sqflite_sw.js'),
    sqlite3WasmUri: Uri.parse('/assets/sqlite3.wasm'),
    indexedDbName: 'my_app_databases',
  ),
);
```

## Guidelines

### createDatabaseFactoryFfiWeb

* Signature: `createDatabaseFactoryFfiWeb({SqfliteFfiWebOptions? options,
  bool noWebWorker = false, String? tag})`. Web only; on io it throws
  `UnsupportedError`.
* Create the factory once (top-level `final` or a singleton). Each factory
  starts its own worker connection / wasm instance on first use, guarded by a
  lock, and keeps it for the life of the page.
* `noWebWorker: true` loads the wasm in the main thread using the same
  options (`sqlite3WasmUri`, `indexedDbName`); `sharedWorkerUri` is ignored.
  `databaseFactoryFfiWebNoWebWorker` is this with default options.
* `tag` (default `ffi_web`) only labels the factory in logs and
  `toString()`.
* Options are sent to the worker before the first database call
  (`setWebOptions`) and the worker loads the wasm and opens the IndexedDB
  store once, at its first database call. A shared worker is keyed by its
  script URL and serves every tab and every factory using that URL, so
  options arriving later (another tab, a second factory with the same
  `sharedWorkerUri`) do not change a running worker. Use one option set per
  worker script; for a different `indexedDbName` or `sqlite3WasmUri` use a
  different `sharedWorkerUri` (a copy of the worker file) or
  `noWebWorker: true`.

### SqfliteFfiWebOptions

* `sqlite3WasmUri` (default `sqlite3.wasm` relative to the page in
  no-worker mode, and relative to the worker script otherwise). Use an
  absolute path (`/sqlite3.wasm`) when the app is served from nested routes.
* `sharedWorkerUri` (default `sqflite_sw.js`): the worker script produced by
  setup. Rename or version it (`sqflite_sw_v2.js`) to force browsers to
  reload the worker after a package upgrade; the setup output name can be
  fixed in the app `pubspec.yaml`:

  ```yaml
  sqflite:
    sqflite_common_ffi_web:
      sw_js_file: sqflite_sw_v2.js
  ```

  then re-run `dart run sqflite_common_ffi_web:setup` and pass the same name
  in `sharedWorkerUri`.
* `indexedDbName` (default `sqflite_databases`): the IndexedDB database
  hosting the virtual file system. Factories with different names (and
  different workers, see above) are fully isolated stores, for example
  production data vs. a scratch store.
* `inMemory`: declared and transported, but the current loader always opens
  the IndexedDB file system; do not rely on it. Use `inMemoryDatabasePath`
  as the database path for a non-persistent database instead.
* `forceAsBasicWorker` is `@visibleForTesting` (used by
  `databaseFactoryFfiWebBasicWebWorker`): forces a dedicated `Worker`
  instead of a `SharedWorker`. Do not set it in application code.
* `SqfliteFfiWebOptionsExt.toMap()` serializes options (useful for logging).

### Lower-level entry points

* `sqfliteFfiWebLoadSqlite3Wasm(options)` opens the IndexedDB file system,
  fetches the wasm and returns a `SqfliteFfiWebContext` (main thread, what
  `noWebWorker` does). `sqfliteFfiWebStartSharedWorker(options)` spawns the
  shared (or basic) worker and returns a context that forwards messages.
  Both are only needed to build a custom worker or to preload; normal code
  uses the factories.
* `SqfliteFfiWebContext` exposes `options`; the web-only extension adds `fs`
  (`VirtualFileSystem` from `package:sqlite3/wasm.dart`), `wasmSqlite3`,
  `sharedWorker` and `sendRawMessage(message)`. The extension lives in
  `src/` and is not part of the public export; treat it as unstable.

### Debugging

* Set `sqliteFfiWebDebugWebWorker = true` (setter is `@Deprecated('testing
  only')`; ignore the warning in a debug build) before the first call to log
  every message sent to and received from the worker (`main_send:` /
  `main_recv:`) and worker start-up steps.
* Inspect the shared worker (console, breakpoints, network) in Chrome at
  `chrome://inspect/#workers`. Application > IndexedDB shows the
  `sqflite_databases` store.
* The database is tied to the origin including the port: keep the same dev
  server port between runs.
* A failure at the first call with the console error "An error occurred
  while initializing the web worker" means the worker script could not be
  loaded (wrong `sharedWorkerUri`, setup not run, file not deployed); the
  message names the URL tried.
* Wrong or outdated `sqlite3.wasm` shows as a load failure inside the worker
  (visible in the worker console); re-run setup with `--force` or download
  the wasm matching the resolved `sqlite3` version.

## Examples

### App served under a sub path with versioned worker

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// Files deployed as /app/sqflite_sw_v2.js and /app/sqlite3.wasm
final DatabaseFactory appDatabaseFactory = createDatabaseFactoryFfiWeb(
  options: SqfliteFfiWebOptions(
    sharedWorkerUri: Uri.parse('/app/sqflite_sw_v2.js'),
    sqlite3WasmUri: Uri.parse('/app/sqlite3.wasm'),
  ),
);

Future<Database> openAppDatabase() =>
    appDatabaseFactory.openDatabase('app.db');
```

### Separate IndexedDB store for tests or scratch data

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// web/sqflite_sw_scratch.js is a copy of web/sqflite_sw.js: a distinct
// worker URL gives a distinct worker, so it can use its own store.
final DatabaseFactory scratchFactory = createDatabaseFactoryFfiWeb(
  options: SqfliteFfiWebOptions(
    sharedWorkerUri: Uri.parse('sqflite_sw_scratch.js'),
    indexedDbName: 'scratch_databases',
  ),
  tag: 'ffi_web_scratch',
);

Future<void> resetScratch() async {
  // Same name as production but a different store: no collision.
  await scratchFactory.deleteDatabase('app.db');
}
```

### Main thread factory with a custom wasm location

```dart
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

final toolFactory = createDatabaseFactoryFfiWeb(
  noWebWorker: true,
  options: SqfliteFfiWebOptions(sqlite3WasmUri: Uri.parse('/wasm/sqlite3.wasm')),
);
```

### Enabling worker message logging in debug builds

```dart
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void enableSqfliteWebLogs() {
  if (kIsWeb && kDebugMode) {
    // ignore: deprecated_member_use
    sqliteFfiWebDebugWebWorker = true;
  }
}
```

## Common mistakes

* Creating a new factory per call: each one spins up its own worker
  connection; keep one instance.
* Changing `indexedDbName` after users have data: the old store is
  orphaned, data appears lost.
* Two factories with different `indexedDbName` but the same worker script:
  both talk to the same running worker and the same store.
* Setting `sharedWorkerUri` without deploying a file at that URL, or
  changing the setup output name without updating the option (or the
  reverse).
* Relying on `inMemory: true` for a private database.
* Using `forceAsBasicWorker` in production code.
* Reading `SqfliteFfiWebContext.fs` from application code (unstable, `src/`).
