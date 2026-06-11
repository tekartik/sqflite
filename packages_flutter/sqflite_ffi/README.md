# sqflite_ffi

sqflite ffi based implementation for flutter, based on
[`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi).

Unlike `sqflite_common_ffi` where each isolate spawns its own sqflite isolate,
the sqflite isolate send port is registered using flutter `IsolateNameServer`
so that all the isolates of an application (main isolate, `compute`,
`Isolate.run`...) share the same sqflite isolate and hence the same database
instances (`singleInstance` works across isolates).

## Getting Started

```dart
import 'package:sqflite_ffi/sqflite_ffi.dart';

Future<void> main() async {
  // Optional (Windows setup).
  sqfliteFfiInit();

  var factory = databaseFactoryFfi;
  var db = await factory.openDatabase(inMemoryDatabasePath);
  // ...
  await db.close();
}
```

On the web, it falls back to the default `sqflite_common_ffi` web factory
(no isolate sharing).
