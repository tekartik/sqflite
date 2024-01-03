# sqflite ffi async

[sqflite](https://pub.dev/packages/sqflite) based ffi implementation. Based
on [`sqlite_async`](https://pub.dev/packages/sqlite_async). Thanks to [PowerSync](https://github.com/powersync-ja)

* Works on Linux, MacOS and Windows on both Flutter and Dart VM.
* Works on iOS and Android (using [sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs) - Thanks
  to [Simon Binder](https://github.com/simolus3))

## Caveats

This is a work in progress.
- Readonly support is provided by `sqflite_common_ffi`
- In memory support is provided by `sqflite_common_ffi`
- Logger is not supported yet.
- Single/multiple instance is ignored as sqflite_async handles opening/closing.