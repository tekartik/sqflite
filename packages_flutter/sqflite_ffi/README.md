# sqflite_ffi

sqflite ffi based implementation for flutter, based on
[`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi).

Unlike `sqflite_common_ffi` where each isolate spawns its own sqflite isolate,
the sqflite isolate send port is registered using flutter `IsolateNameServer`
so that all the isolates of an application (main isolate, `compute`,
`Isolate.run`...) share the same sqflite isolate and hence the same database
instances (`singleInstance` works across isolates).

## Getting Started

`sqflite_ffi` is a (dart only) flutter plugin: at startup
`SqfliteFfiPlugin.registerWith()` is called automatically, initializes ffi
(Windows specific setup) and sets `sqfliteDatabaseFactoryFfi` as the default
database factory (unless another factory - for example the native `sqflite`
plugin - is already registered). So the global sqflite API works directly:

```dart
import 'package:sqflite_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var db = await openDatabase(inMemoryDatabasePath);
  // ...
  await db.close();
}
```

The factory can also be used explicitly:

```dart
Future<Database> openMyDatabase() async {
  var factory = sqfliteDatabaseFactoryFfi;
  return await factory.openDatabase(inMemoryDatabasePath);
}
```

In background isolates not started by the flutter engine, plugin registration
does not happen automatically; either call
`DartPluginRegistrant.ensureInitialized()` or use `sqfliteDatabaseFactoryFfi`
directly.

On the web, no op.
