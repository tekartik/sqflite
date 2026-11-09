# sqflite_platform_interface

The platform interface of the [sqflite](https://pub.dev/packages/sqflite)
Flutter plugin: the base of a platform implementation of sqflite, like
`sqflite_android` and `sqflite_darwin`.

[![pub package](https://img.shields.io/pub/v/sqflite_platform_interface.svg)](https://pub.dev/packages/sqflite_platform_interface)

An application does not depend on it. It uses
[sqflite](https://pub.dev/packages/sqflite) (Android, iOS, macOS),
[sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) (Windows,
Linux, Dart VM, unit tests) or
[sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web)
(web).

## Getting started

In your implementation package (a Flutter plugin package):

```sh
flutter pub add sqflite_platform_interface sqflite_common
```

If the native side of your package speaks the sqflite method channel protocol
(as the Android and iOS/macOS code does), register the method channel factory
from the `registerWith()` of a `SqflitePlatform` subclass:

```dart
import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

/// sqflite implementation for "myos".
class SqfliteMyOs extends SqflitePlatform {
  /// Called by Flutter before `main()` (the `dartPluginClass`).
  static void registerWith() {
    SqflitePlatform.initWithDatabaseFactoryMethodChannel();
  }
}
```

and declare it in its `pubspec.yaml`:

```yaml
flutter:
  plugin:
    implements: sqflite
    platforms:
      myos:
        pluginClass: SqflitePlugin
        dartPluginClass: SqfliteMyOs
```

An app using `sqflite` then calls `openDatabase()` as usual on this platform.

## What it provides

| API | Use it to |
|---|---|
| `SqflitePlatform.initWithDatabaseFactoryMethodChannel()` | set the method channel factory as the global `databaseFactory` (an already set factory is kept) |
| `SqflitePlatform.databaseFactoryMethodChannel` | get the method channel `DatabaseFactory` (channel `com.tekartik.sqflite`) |
| `SqflitePlatform().databaseFactory` | get or set the global `databaseFactory` of `sqflite_common` |

The method channel factory runs the shared sqflite Dart code of
`sqflite_common` (versions, transactions, batches, single instances) and sends
the SQL to the native side. The messages are described in
[method_call_protocol.md](https://github.com/tekartik/sqflite/blob/master/sqflite_common/doc/method_call_protocol.md).
`readDatabaseBytes()` and `writeDatabaseBytes()` do not go through the
channel: they read and write the file in Dart (`dart:io`), a relative path
being in the databases path, as for `openDatabase()`.

A Dart implementation (ffi, web) does not need the channel: its
`registerWith()` sets its own factory, keeping one already set, as
[sqflite_ffi](https://pub.dev/packages/sqflite_ffi) does:

```dart
import 'package:sqflite_common/sqflite.dart';

/// [factory] is built with the sqflite_common helpers (for example
/// `databaseFactoryFfi` of sqflite_common_ffi).
void registerDartFactory(DatabaseFactory factory) {
  databaseFactoryOrNull ??= factory;
}
```

## Common mistakes

* Depending on this package from an app: use `sqflite`.
* No `dartPluginClass` in the pubspec: `registerWith()` never runs and
  `openDatabase()` throws `StateError: databaseFactory not initialized`.
* Native errors with a code other than `sqlite_error`: the app gets a
  `PlatformException` instead of a `DatabaseException`.
* Setting a class that only `implements DatabaseFactory`: the setter throws
  `ArgumentError` (`Unsupported sqflite factory`). Build the factory with the
  `sqflite_common` helpers (`buildDatabaseFactory`).

## Implementations

* [sqflite_android](https://github.com/tekartik/sqflite/tree/master/sqflite_android)
  (Android, [example](https://github.com/tekartik/sqflite/tree/master/sqflite_android/example))
* [sqflite_darwin](https://github.com/tekartik/sqflite/tree/master/sqflite_darwin)
  (iOS and macOS, [example](https://github.com/tekartik/sqflite/tree/master/sqflite_darwin/example))
* [sqflite](https://github.com/tekartik/sqflite/tree/master/sqflite), the
  app-facing package, and its
  [example](https://github.com/tekartik/sqflite/tree/master/sqflite/example)
