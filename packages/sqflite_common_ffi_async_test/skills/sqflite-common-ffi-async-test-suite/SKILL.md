---
name: sqflite-common-ffi-async-test-suite
description: >-
  Use when testing package:sqflite_common_ffi_async (the sqlite_async based
  sqflite DatabaseFactory) against the shared sqflite suite with
  sqflite_common_ffi_async_test: runFfiAsyncTests(context),
  the all: true full-suite switch, building the SqfliteTestContext
  (SqfliteLocalTestContext, supportsConcurrentRead, supportsUri),
  databaseFactoryFfiAsync / databaseFactoryFfiAsyncTest, which
  sqflite_common_test suites are known to pass or fail, and @TestOn('vm').
---

# Shared test suite for the ffi async factory (sqflite_common_ffi_async_test)

`sqflite_common_ffi_async_test` is a thin runner over `sqflite_common_test`: it
knows which parts of the shared sqflite suite `sqflite_common_ffi_async`
currently passes and exposes them as a single call,
`runFfiAsyncTests(context)`.

## Guidelines

* Dependency (not on pub.dev, `publish_to: none`), in `dev_dependencies`:
  ```yaml
  dev_dependencies:
    sqflite_common_ffi_async_test:
      git:
        url: https://github.com/tekartik/sqflite
        path: packages/sqflite_common_ffi_async_test
    sqflite_common_test:
      git:
        url: https://github.com/tekartik/sqflite
        path: sqflite_common_test
      version: '>=0.3.0'
  ```
  `sqflite_common_test` is needed for `SqfliteTestContext` /
  `SqfliteLocalTestContext`; `sqflite_common_ffi_async` for the factory.
* Single entry point:
  `package:sqflite_common_ffi_async_test/all_test.dart` exports
  `runFfiAsyncTests(SqfliteTestContext context, {bool all = false})`. Call it
  at `main()` level, never inside `test()` or `setUp()`. Everything it defines
  lands in a `group('all', ...)`.
* Default run (`all` left to `false`) declares the suites known to pass:
  `database_factory_test`, `doc_test` (with `noLoggerTest: true`), `batch_test`
  (`noManualTransactionTest: true`), `exp_test` (`noMultipleStatement: true`),
  `slow_test`, `type_test`, `statement_test`, `raw_test`, `issue_test` and
  `walTests`. This is the CI run.
* `runFfiAsyncTests(context, all: true)` additionally declares the whole
  shared suite (`protocol_test`, `service_impl_test`, `open_test`,
  `open_flutter_test`, `exception_test`,
  `transaction_test`, the unrestricted `doc_test`/`batch_test`/`exp_test`...).
  Those still have known failures (logger, protocol, exception parsing,
  delete/exists edge cases): use it in a separate `*_all` test file to
  investigate, not as the gate.
* Build the context with `SqfliteLocalTestContext` from
  `package:sqflite_common_test/sqflite_test.dart`, and set the two flags that
  differ for this implementation: `supportsConcurrentRead => true` (it is the
  only sqflite factory with a read pool) and `supportsUri => false` (no `file:`
  uri paths, unlike `databaseFactoryFfi`).
* Factory: `databaseFactoryFfiAsync` from
  `package:sqflite_common_ffi_async/sqflite_ffi_async.dart`;
  `databaseFactoryFfiAsyncTest` is the same implementation with a separate tag
  when a test must not share state with application code. No `sqfliteFfiInit()`
  call is needed, contrary to `sqflite_common_ffi`.
* VM only: put `@TestOn('vm')` before `library;`. Run with `dart test`
  (or `flutter test` in a Flutter package). The suite is file based, so it
  writes under the factory's databases path; give a parallel second suite file
  its own path with `setDatabasesPath` in an `async` `main()`.
* Single shared suites can also be run straight from `sqflite_common_test`
  (`raw_test.run(context)`, `walTests(context)`...) when narrowing down a
  failure; see the `sqflite-common-test-suite` skill for the full list.
* Debugging a failing test: wrap the factory in
  `databaseFactoryFfiAsync.debugQuickLoggerWrapper()` (deprecated, dev only,
  needs an `// ignore: deprecated_member_use`) to print every invoked method.

## Examples

### Standard suite run (CI)

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';
import 'package:sqflite_common_ffi_async_test/all_test.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

class SqfliteFfiAsyncTestContext extends SqfliteLocalTestContext {
  SqfliteFfiAsyncTestContext()
    : super(databaseFactory: databaseFactoryFfiAsync);

  @override
  bool get supportsConcurrentRead => true;

  @override
  bool get supportsUri => false;
}

void main() {
  runFfiAsyncTests(SqfliteFfiAsyncTestContext());
}
```

### Full suite, with known failures, in its own file and databases path

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';
import 'package:sqflite_common_ffi_async_test/all_test.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

final _factory = databaseFactoryFfiAsyncTest;

Future<void> main() async {
  var dbsPath = await _factory.getDatabasesPath();
  await _factory.setDatabasesPath('${dbsPath}_ffi_async_all');

  runFfiAsyncTests(
    SqfliteLocalTestContext(databaseFactory: _factory),
    all: true,
  );
}
```

### Narrowing down: one shared suite only

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';
import 'package:sqflite_common_test/raw_test.dart' as raw_test;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_common_test/transaction_test.dart' as transaction_test;
import 'package:test/test.dart';

void main() {
  var context = SqfliteLocalTestContext(
    databaseFactory: databaseFactoryFfiAsync,
  );
  raw_test.run(context);
  transaction_test.run(context);
}
```

### Own concurrency test on top of the same context

```dart
@TestOn('vm')
library;

import 'dart:async';

import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

void main() {
  var context = SqfliteLocalTestContext(
    databaseFactory: databaseFactoryFfiAsync,
  );

  test('two read transactions overlap', () async {
    var path = await context.initDeleteDb('concurrent_read.db');
    var db = await context.databaseFactory.openDatabase(path);
    try {
      await db.execute('CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)');
      var first = Completer<void>();
      var second = Completer<void>();

      unawaited(
        db.readTransaction((txn) async {
          first.complete();
          await second.future; // held open while the second one runs
        }),
      );
      await first.future;
      await db.readTransaction((txn) async {
        expect(await txn.query('Item'), isEmpty);
        second.complete();
      });
    } finally {
      await db.close();
    }
  });
}
```
