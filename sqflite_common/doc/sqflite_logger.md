# sqflite_logger

There are 6 types of events:
- SqfliteLoggerSqlEvent,
- SqfliteLoggerDatabaseOpenEvent,
- SqfliteLoggerDatabaseCloseEvent,
- SqfliteLoggerDatabaseDeleteEvent,
- SqfliteLoggerInvokeEvent,
- SqfliteLoggerBatchEvent,
  
The original idea is that the logger function should test the type of the event to choose what to display.
For example if it is a `SqfliteLoggerSqlEvent`, the function can directly access the `sql` and `arguments` parameter to pick and build its own logging system.

The example below should print
```
sql: CREATE TABLE Test (id INTEGER PRIMARY KEY)
sql: BEGIN IMMEDIATE
sql(batch): INSERT INTO Test (id) VALUES (?) [1]
sql(batch): INSERT INTO Test (id) VALUES (?) [2]
sql: COMMIT
```

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite_common/sqflite_dev.dart';
import 'package:sqflite_common/sqflite_logger.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

Future main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  test('logger', () async {
    /// Log sql commands
    void _logger(SqfliteLoggerEvent event) {
      /// Check the event type
      if (event is SqfliteLoggerSqlEvent) {
        print(
            'sql: ${event.sql}${event.arguments != null ? ' ${event.arguments}' : ''}');
      } else if (event is SqfliteLoggerBatchEvent) {
        /// The batch contains a list of operations
        for (var operation in event.operations) {
          print(
              'sql(batch): ${operation.sql}${operation.arguments != null ? ' ${operation.arguments}' : ''}');
        }
      }
    }

    final factoryWithLogs = SqfliteDatabaseFactoryLogger(
      databaseFactoryFfi,
      options: SqfliteLoggerOptions(
        log: _logger,
        type: SqfliteDatabaseFactoryLoggerType.all,
      ),
    );
    var db = await factoryWithLogs.openDatabase(inMemoryDatabasePath);
    // Ok
    await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
    var batch = db.batch();
    batch.insert('Test', {'id': 1});
    batch.insert('Test', {'id': 2});
    await batch.commit();
    await db.query('Test');
    await db.close();
  });
}
```

Something more verbose would be
```dart
void _logger(SqfliteLoggerEvent event) {
  /// Check the event type
  if (event is SqfliteLoggerSqlEvent) {
    var map = <String, dynamic>{
      'sql': event.sql,
      if (event.arguments != null) 'arguments': event.arguments,
      if (event.error != null) 'error': event.error.toString(),
      if (event.sw != null) 'sw': event.sw!.elapsed.toString(),
    };
    print(JsonEncoder.withIndent('  ').convert(map));
  } else if (event is SqfliteLoggerBatchEvent) {
    /// The batch contains a list of operations
    for (var operation in event.operations) {
      var map = <String, dynamic>{
        'sql': operation.sql,
        if (operation.arguments != null) 'arguments': operation.arguments,
        if (operation.error != null) 'error': operation.error.toString(),
      };
      print(JsonEncoder.withIndent('  ').convert(map));
    }
  }
}
```

and would print
```
{
  "sql": "CREATE TABLE Test (id INTEGER PRIMARY KEY)",
  "sw": "0:00:00.000204"
}
{
  "sql": "BEGIN IMMEDIATE",
  "sw": "0:00:00.000121",
  "result": {
    "transactionId": 1
  }
}
{
  "sql": "INSERT INTO Test (id) VALUES (?)",
  "arguments": [
    1
  ],
  "result": 1
}
{
  "sql": "INSERT INTO Test (id) VALUES (?)",
  "arguments": [
    2
  ],
  "result": 2
}
{
  "sql": "COMMIT",
  "sw": "0:00:00.000109"
}
{
  "sql": "SELECT * FROM Test",
  "sw": "0:00:00.000211",
  "result": [
    {
      "id": 1
    },
    {
      "id": 2
    }
  ]
}
```