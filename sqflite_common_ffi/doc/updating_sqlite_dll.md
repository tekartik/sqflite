# Updating SQLite DLL

This projects ships with a precompiled version of the SQLite DLL for Windows that allows running dart and flutter app
without additional setup. This version might not be the latest available at https://www.sqlite.org/download.html.

You should grab and copy a fresh version of sqlite3.dll for your released app to bundle with your app.

## Upgrading SQLite dll

`sqlite3_info.dart` can be modified to download a new version of the SQLite DLL by running `tool/windows_setup.dart`.
