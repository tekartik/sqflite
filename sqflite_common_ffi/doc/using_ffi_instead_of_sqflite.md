# Using sqflite_ffi instead of sqflite

Currently (as of 2020/07/01) sqflite only supports iOS/Android/MacOS. `sqflite_common_ffi` allows supporting Windows and Linux
on DartVM or flutter.

* [sqflite_common](https://pub.dev/packages/sqflite_common) provides an abstracted [`DatabaseFactory`](https://pub.dev/documentation/sqflite_common/latest/sqlite_api/DatabaseFactory-class.html) that allows another level
  of abstraction (for any target, not only flutter) above the plugin mechanism which is only for flutter.
* [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) defines a global `databaseFactoryFfi` allowing supporting Linux and Windows on Flutter and on DartVM.
  It uses [sqlite3](https://pub.dev/packages/sflite3) so also works on iOS and Android using [sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs)
* [sqflite](https://pub.dev/packages/sqflite) provides a direct API (openDatabase, deleteDatabase) that uses a global `databaseFactory` that can be modified.

Ideally, packages requiring sqlite feature should only require a [`DatabaseFactory`](https://pub.dev/documentation/sqflite_common/latest/sqlite_api/DatabaseFactory-class.html) parameter to allow using any implementation.
For convenience and targetting only flutter, 3rd party packages (cached_network_image for example) uses the direct API.

sqflite implementation uses a global `databaseFactory` that could be replace so that it will bypass the regular sqflite
plugin implementation.

Simply doing `databaseFactory = databaseFactoryFFi;` should bring Linux and Windows support.

## Setup

First add the dependency:

```
dependencies:
  sqflite_common_ffi:
```

On iOS, Android and MacOS, add
```
dependencies:
  sqlite3_flutter_libs:
```

## Initialization

Then initialize ffi before running your app:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

Future main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
  }
  // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
  // this step, it will use the sqlite version available on the system.
  databaseFactory = databaseFactoryFfi;
  runApp(MyApp());
}
```

As a side note, `sqfliteFfiInit` is only made to be convenient during development. You can customize the setup (finding/loading the sqlite shared library) by
following [sqlite3](https://pub.dev/packages/sqlite3) documentation.

As another note, `getDatabasesPath()` has a lame implementation when using ffi. you'd better rely on a custom strategy using package such as `path_provider`.

## Long term planning

I can see multiple solutions that could co-exist:
* sqflite would provide a solution that works out of the box on all platforms using whatever the platform provides using regular plugin mechanism. (current state, not planned, see [cross-platform-support](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/qa.md#cross-platform-support))
* sqflite would provide a solution using ffi and whatever the platform provides
* sqflite would allow having a compiled sqlite.c and access it using either ffi or the regular plugin mechanism