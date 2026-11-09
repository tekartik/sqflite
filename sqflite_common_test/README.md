# sqflite_common_test

The shared conformance test suite of sqflite: several hundred tests (open and
versions, raw SQL, batches, transactions, value types, exceptions, WAL,
method call protocol) to run against a `DatabaseFactory` implementation. Every
sqflite implementation is checked with it: `sqflite_common_ffi`,
`sqflite_common_ffi_web`, `sqflite_common_ffi_async` and the native plugin.

## Getting started

It is not on pub.dev, add it as a git dev dependency, next to the
implementation under test (here `sqflite_common_ffi`):

```yaml
dev_dependencies:
  sqflite_common_test:
    git:
      url: https://github.com/tekartik/sqflite
      path: sqflite_common_test
  sqflite_common_ffi: ^2.4.5
  test: ^1.24.0
```

Then give the suite a test context wrapping your factory, in
`test/my_sqflite_test.dart`:

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// The ffi factory, with the features it supports.
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

and run it:

```sh
dart test test/my_sqflite_test.dart
```

Platforms:
* Dart VM (`dart test`): an io factory, such as `databaseFactoryFfi`.
* Browser (`dart test -p chrome`, `@TestOn('browser')`): a web factory, such
  as the one of `sqflite_common_ffi_web`.
* Flutter plugin: from an `integration_test` on a device, the suite being
  declared inside a `flutter_test` `group()` (see `sqflite_plugin_test_app`
  in this repository).

## What it provides

* `SqfliteLocalTestContext(databaseFactory: ...)`: the test context to
  subclass; it creates and deletes the test databases under the factory's
  databases path.
* Capability flags to override for what the implementation supports (all
  default to the conservative value): `supportsUri`, `supportsWithoutRowId`,
  `supportsDeadLock`, `supportsConcurrentRead`, `supportsMultipleInstances`,
  `supportsRecoveredInTransaction`, `strict`, `isPlugin`.
* `all_test.dart` `run(context)`: the whole suite. Each suite library
  (`raw_test.dart`, `batch_test.dart`, `open_test.dart`,
  `transaction_test.dart`, `type_test.dart`, `exception_test.dart`...) also
  has its own `run(context)`; `wal_test.dart` has `walTests(context)`.
* `database_factory_mock.dart`: `databaseFactoryMock`, a `DatabaseFactory`
  whose methods all throw, for code that must not use the database.

## Common mistakes

* Calling `run(context)` inside a `test()` or `setUp()`: it declares tests,
  call it from `main()` (or a `group()`).
* Two test files running the suite on the same databases path (they run in
  parallel): give each one its own path with
  `await factory.setDatabasesPath('${await factory.getDatabasesPath()}_mine')`
  in an `async` `main()`.
* Turning a `supports*` flag on to hide a failing test: it hides a real gap
  of the implementation.
* Forgetting the initializer of the implementation (`sqfliteFfiInit()` for
  ffi) before `run()`.

More examples (a few suites only, your own tests with the context helpers):
the `sqflite-common-test-suite` skill in
[skills/](https://github.com/tekartik/sqflite/tree/master/sqflite_common_test/skills),
and the [test/](https://github.com/tekartik/sqflite/tree/master/sqflite_common_test/test)
folder, which runs the suite on `sqflite_common_ffi`.
