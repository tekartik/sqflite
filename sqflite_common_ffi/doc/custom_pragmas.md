# Custom pragmas

This allows calling internal API through `execute(pragma)` without adding more entry points.

## `PRAGMA sqflite -- db_config_defensive_off`

This pragma is used to disable the [SQLite defensive mode](https://www.sqlite.org/c3ref/c_dbconfig_defensive.html) which is enabled by default in sqflite.
This allows `PRAGMA writable_schema=ON statement.`

Can be also reproduced in iOS 14 (and implemented sqflite iOS too).

See:
* https://github.com/tekartik/sqflite/pull/1058
* https://github.com/tekartik/sqflite/issues/525