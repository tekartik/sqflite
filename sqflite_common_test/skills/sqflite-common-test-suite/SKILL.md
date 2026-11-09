---
name: sqflite-common-test-suite
description: >-
  Use when running the shared sqflite conformance test suite against a
  DatabaseFactory implementation (ffi, ffi async, web, the native plugin or a
  custom one) with sqflite_common_test: SqfliteTestContext,
  SqfliteLocalTestContext, SqfliteTestContextMixin,
  SqfliteLocalTestContextMixin, all_test.dart run/sqfliteTestGroup, the
  individual suites (raw_test, batch_test, open_test, transaction_test,
  type_test, exception_test, doc_test, wal_test walTests,
  sqflite_protocol_test), the capability flags supportsUri, supportsDeadLock,
  supportsWithoutRowId, supportsConcurrentRead, supportsMultipleInstances,
  strict, isPlugin, and databaseFactoryMock.
---

# Shared sqflite test suite (sqflite_common_test)

`sqflite_common_test` is the conformance suite every sqflite implementation is
validated with: give it a `SqfliteTestContext` wrapping a `DatabaseFactory`
and it defines hundreds of `test()`s (open/upgrade, raw SQL, batch,
transactions, types, exceptions, WAL, protocol) in the calling test file.

## Guidelines

* Dependency (not on pub.dev, `publish_to: none`), in `dev_dependencies`:
  ```yaml
  dev_dependencies:
    sqflite_common_test:
      git:
        url: https://github.com/tekartik/sqflite
        path: sqflite_common_test
      version: '>=0.3.0'
  ```
  It pulls `sqflite_common`, `test`, `path` and `synchronized`, not the
  implementation under test: add it too (for example `sqflite_common_ffi`,
  only a dev dependency of the suite itself).
* Two imports are enough for the common case:
  `package:sqflite_common_test/sqflite_test.dart` (the context types) and
  `package:sqflite_common_test/all_test.dart` (the whole suite). Import
  `all_test.dart` with a prefix (`as all`): every suite library exports a
  top-level `run`.
* Entry points of `all_test.dart`: `run(SqfliteTestContext context)` and
  `sqfliteTestGroup(SqfliteTestContext context)` are the same thing; call it
  from `main()`, optionally inside your own `group('ffi', ...)`.
* Build the context with `SqfliteLocalTestContext(databaseFactory: ...)` — a
  file-based context (`dart:io`) that creates/deletes directories under the
  factory's databases path. Subclass it to flip the capability flags of the
  implementation under test.
* Capability flags (all default to the conservative value in
  `SqfliteTestContextMixin`, override only what the implementation supports):
  * `supportsUri` (`false`): `file:` uri paths, true for ffi.
  * `supportsWithoutRowId` (`false`): `CREATE TABLE ... WITHOUT ROWID`.
  * `supportsDeadLock` (`false`): enables the multi-instance dead lock tests.
  * `supportsConcurrentRead` (`false`): only `sqflite_common_ffi_async` sets it.
  * `supportsMultipleInstances` (`!isWeb`): `singleInstance: false`.
  * `supportsRecoveredInTransaction` (`false`): native android/ios/macos only.
  * `strict` (`true`): the implementation rejects loosely typed queries.
  * `isPlugin` (`false`): true only for the native `sqflite` plugin factory.
  `isWeb`, `isAndroid`, `isIOS`, `isMacOS`, `isLinux`, `isWindows` come from
  the mixins; do not override them.
* Always call the implementation initializer before `run()` (for ffi:
  `sqfliteFfiInit()` from `package:sqflite_common_ffi/sqflite_ffi.dart`).
* Two test files running the suite in the same package run in parallel and
  share the databases path. Give each one its own directory with
  `await factory.setDatabasesPath('${await factory.getDatabasesPath()}_suffix')`
  in an `async` `main()` before `run()`.
* Add `@TestOn('vm')` (before `library;`) to a suite file using a VM-only
  factory, `@TestOn('browser')` for a web factory, in a package that also
  runs tests on the other platform.
* Individual suites, when the whole suite is too much or one area fails:
  import `package:sqflite_common_test/<name>.dart` and call its `run(context)`
  — `raw_test`, `batch_test` (`run(context, noManualTransactionTest: true)`),
  `open_test`, `open_flutter_test`, `transaction_test`, `type_test`,
  `exception_test`, `exp_test` (`noMultipleStatement: true`), `doc_test`
  (`noLoggerTest: true`), `iterate_test`, `slow_test`, `statement_test`,
  `sql_command_test`, `database_factory_test`, `service_impl_test`,
  `issue_test`. `wal_test.dart` exports `walTests(context)` (not `run`) and
  `sqflite_protocol_test.dart` exports `run(SqfliteTestContext?)`, which
  accepts `null` and then checks the invoke-method protocol against an
  internal mock factory, no real database needed.
* Context helpers usable in your own tests: `await context.initDeleteDb('x.db')`
  returns a deleted absolute path ready to open, `createDirectory(null)` gives
  the databases path, `deleteDirectory(path)`, `writeFile(path, bytes)`,
  `isInMemoryPath(path)`, `pathContext` (a `package:path` `Context`).
* `package:sqflite_common_test/database_factory_mock.dart` gives
  `DatabaseFactoryMock` / `databaseFactoryMock`: every method throws
  `UnimplementedError`. Use it to satisfy a `DatabaseFactory` parameter that
  the code under test must not call, never to fake results.
* Anti-patterns: calling `run(context)` inside `test()` or `setUp()` (it
  declares tests, so it must run at `main()` level); sharing one databases
  path between suite runs; overriding a `supports*` flag to `true` to make a
  failing test disappear — it hides a real implementation gap.

## Examples

### Whole suite against the ffi factory

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

class FfiTestContext extends SqfliteLocalTestContext {
  FfiTestContext() : super(databaseFactory: databaseFactoryFfi);

  @override
  bool get supportsUri => true;
}

void main() {
  sqfliteFfiInit();
  all.run(FfiTestContext());
}
```

### Isolated databases path, so two suite files can run in parallel

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

final _factory = createDatabaseFactoryFfi(noIsolate: true);

Future<void> main() async {
  sqfliteFfiInit();
  var dbsPath = await _factory.getDatabasesPath();
  await _factory.setDatabasesPath('${dbsPath}_no_isolate');

  group('ffi_no_isolate', () {
    all.run(SqfliteLocalTestContext(databaseFactory: _factory));
  });
}
```

### Only a few suites, plus the protocol suite with no factory

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/batch_test.dart' as batch_test;
import 'package:sqflite_common_test/raw_test.dart' as raw_test;
import 'package:sqflite_common_test/sqflite_protocol_test.dart' as protocol_test;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_common_test/transaction_test.dart' as transaction_test;
import 'package:sqflite_common_test/wal_test.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  var context = SqfliteLocalTestContext(databaseFactory: databaseFactoryFfi);
  raw_test.run(context);
  batch_test.run(context, noManualTransactionTest: true);
  transaction_test.run(context);
  walTests(context);
  protocol_test.run(null); // mock based, no real database
}
```

### Own tests reusing the context helpers

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  var context = SqfliteLocalTestContext(databaseFactory: databaseFactoryFfi);

  test('my schema survives a reopen', () async {
    var path = await context.initDeleteDb('my_schema.db');
    var db = await context.databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) =>
            db.execute('CREATE TABLE Item (id INTEGER PRIMARY KEY)'),
      ),
    );
    await db.close();

    db = await context.databaseFactory.openDatabase(path);
    expect(await db.query('Item'), isEmpty);
    await db.close();
  });
}
```

### A DatabaseFactory the code under test must not touch

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_test/database_factory_mock.dart';
import 'package:test/test.dart';

class Repository {
  Repository(this.factory);
  final DatabaseFactory factory;
  bool get isConfigured => true; // never opens the database
}

void main() {
  test('no database access on construction', () {
    var repository = Repository(databaseFactoryMock);
    expect(repository.isConfigured, isTrue);
  });
}
```
