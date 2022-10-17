# Method call protocol

This protocol is used in a similar way for:
- sqflite plugin
- sqflite_common_ffi isolate communication
- sqflite_common_ffi_web web worker communication

## Methods

### openDatabase

```
in:
    path: database path (String)
    readOnly: <true|false>
    singleInstance: <true|false>

out:
    id: database id (int)
    recoveredInTransaction: <true|false>
```

### query

`SELECT` method

```
in:
    sql: select query (String)
    arguments: [<param1>, <param2>...] (binding parameters)
    cursorPageSize: <count> new in 2022-10-17 if non null the cursor is kept

out:
    columns: [<name1>, <name2>...]
    rows: [
            [row1 value1, row2 value2, ...]
            [row2 value1, row2 value2, ...]
            ...
          ] 
    cursorId: <id> optional cursor id for queryNext, null if end is reached
```

### queryCursorNext

Added in 2022-10-17 to support pages queries

```
in:
    cursorId: <id>
    cancel: <true|false> true if the query should be cancelled

out:
    columns: [<name1>, <name2>...]
    rows: [
            [row1 value1, row2 value2, ...]
            [row2 value1, row2 value2, ...]
            ...
          ] 
    cursorId: <id> optional cursor id for queryNext, null if end is reached
```