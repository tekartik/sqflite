# Updating SQLite DLL

Only for `sqflite_common_ffi` before 2.4.0 (`sqlite3` v2). Since 2.4.0, `sqlite3` 3.x
bundles SQLite on Windows with build hooks and no dll is shipped with this package.

This projects ships with a precompiled version of the SQLite DLL for Windows that allows running dart and flutter app
without additional setup. This version might not be the latest available at https://www.sqlite.org/download.html.

You should grab and copy a fresh version of sqlite3.dll for your released app to bundle with your app.

## Upgrading SQLite dll

`sqlite3_info.dart` can be modified to download a new version of the SQLite DLL by running `tool/windows_setup.dart`.
