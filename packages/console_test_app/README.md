# Simple console test app

Checks that `sqflite_common_ffi` works in a command line program run from
another directory, and compiled with `dart build cli` (the `sqlite3` build
hooks bundle SQLite).

```sh
dart run bin/sqflite_ffi_simple_bin.dart
dart test
```

The `dart pub global activate` and `dart install` tests are skipped (build
hooks issue).
