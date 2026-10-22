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

## Databases path

Relative database paths (and `getDatabasesPath()`) resolve to
`.dart_tool/sqflite_common_ffi/databases` in the current directory, the
`sqflite_common_ffi` default. That is fine when running from the project
folder on desktop (`flutter run`, `flutter test`) but not in a real
application:

- on Android and iOS the current directory is `/`, which is not writable,
  so opening a database fails;
- on desktop an installed application can be started from any directory.

`sqflite_ffi` does not depend on `path_provider`, so set the databases path
yourself once in `main()`, before opening any database, typically with
[`path_provider`](https://pub.dev/packages/path_provider) and
[`path`](https://pub.dev/packages/path) added to your app.

### Per platform

| Platform | Native sqflite plugin folder | path_provider code |
|---|---|---|
| Android | `/data/user/0/<package>/databases` | `join(dirname((await getApplicationSupportDirectory()).path), 'databases')` |
| iOS | Documents | `(await getApplicationDocumentsDirectory()).path` |
| macOS | Documents (inside the container for a sandboxed app) | `(await getApplicationDocumentsDirectory()).path` |
| Linux | none | `join((await getApplicationSupportDirectory()).path, 'databases')` (`~/.local/share/<application id>/databases`) |
| Windows | none | `join((await getApplicationSupportDirectory()).path, 'databases')` (`%APPDATA%\<company>\<product>\databases`) |

Use the native folders to keep the databases of an existing app moving from
`sqflite` to `sqflite_ffi`:

```dart
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// The folders used by the native sqflite plugin on Android, iOS and macOS,
/// the application support directory on Linux and Windows.
Future<String> sqflitePluginDatabasesPath() async {
  if (Platform.isAndroid) {
    // The files directory and the databases directory share the same parent,
    // the application data directory.
    var supportDir = await getApplicationSupportDirectory();
    return join(dirname(supportDir.path), 'databases');
  } else if (Platform.isIOS || Platform.isMacOS) {
    return (await getApplicationDocumentsDirectory()).path;
  }
  return join((await getApplicationSupportDirectory()).path, 'databases');
}
```

### One location for all platforms

For a new app, a `databases` folder in the application support directory
works everywhere with the same code. It is private to the application,
writable, not shown to the user (unlike Documents on iOS or on a non
sandboxed macOS app), and the location used by the
[`sqflite_ffi_test_app`](https://github.com/tekartik/sqflite/tree/master/packages_flutter/sqflite_ffi_test_app):

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

/// A `databases` folder in the application support directory.
Future<String> appDatabasesPath() async {
  var supportDir = await getApplicationSupportDirectory();
  return join(supportDir.path, 'databases');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await databaseFactory.setDatabasesPath(await appDatabasesPath());
  }
  // Relative paths now resolve in the application support directory.
  var db = await openDatabase('app.db');
  // ...
}
```

The path is set on the factory of the isolate calling `setDatabasesPath`. In
a `compute` or `Isolate.run` callback, pass the full database path (from
`join(await getDatabasesPath(), 'app.db')` in the main isolate) rather than a
relative one.
