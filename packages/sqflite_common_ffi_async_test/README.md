# sqflite_common_ffi_async_test

Runs the shared sqflite test suite (`sqflite_common_test`) on
`sqflite_common_ffi_async` (the `sqlite_async` based factory). Not published.

```bash
# The suites known to pass (the CI run)
dart test test/sqflite_ffi_async_test.dart
# The whole shared suite, with known failures (to investigate)
dart test test/sqflite_ffi_async_test_all.dart
```

`runFfiAsyncTests(context, {all})` in `lib/all_test.dart` lists the suites,
see the `sqflite-common-ffi-async-test-suite` skill.
