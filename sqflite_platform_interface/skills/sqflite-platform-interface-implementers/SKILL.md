---
name: sqflite-platform-interface-implementers
description: >-
  Use when implementing or registering a platform implementation of the
  sqflite federated plugin (a new sqflite_<platform> package, a custom
  DatabaseFactory registered as the default): SqflitePlatform,
  SqflitePlatform.initWithDatabaseFactoryMethodChannel,
  databaseFactoryMethodChannel, the databaseFactory getter/setter, the
  dartPluginClass registerWith() hook, the com.tekartik.sqflite method channel
  and its method names (openDatabase, query, insert, update, execute, batch).
  Not for app code: apps use package:sqflite.
---

# sqflite_platform_interface: writing a platform implementation

`package:sqflite_platform_interface` is the common interface of the `sqflite`
federated plugin. `sqflite` (the app-facing package) declares
`sqflite_android` and `sqflite_darwin` as default implementations; both are
`SqflitePlatform` subclasses whose `registerWith()` installs the method
channel `DatabaseFactory` as the global `databaseFactory` of
`package:sqflite_common`. Depend on this package only from an implementation
package; apps depend on `sqflite`.

```dart
import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

/// Referenced as `dartPluginClass` in pubspec.yaml.
class SqfliteMyPlatform extends SqflitePlatform {
  static void registerWith() {
    // Native side speaks the com.tekartik.sqflite method channel protocol.
    SqflitePlatform.initWithDatabaseFactoryMethodChannel();
  }
}
```

## Guidelines

* Extend `SqflitePlatform` (it extends `PlatformInterface` with a private
  token; `implements` is rejected by `PlatformInterface.verify`).
* Expose a static `registerWith()` and declare it in the implementation
  package `pubspec.yaml` under `flutter: plugin: platforms: <platform>:
  dartPluginClass: <Class>`, together with `pluginClass` (and `package` on
  Android) for the native side. Flutter calls it before `main()`.
* If your native code implements the sqflite method channel protocol
  (channel `com.tekartik.sqflite`, methods `openDatabase`, `closeDatabase`,
  `query`, `queryCursorNext`, `insert`, `update`, `execute`, `batch`,
  `getDatabasesPath`, `databaseExists`, `deleteDatabase`,
  `readDatabaseBytes`, `writeDatabaseBytes`, `options`, `debug`), call
  `SqflitePlatform.initWithDatabaseFactoryMethodChannel()` from
  `registerWith()`. It sets `databaseFactoryOrNull ??=
  SqflitePlatform.databaseFactoryMethodChannel`, so an already registered
  factory is kept. The wire format is described in
  `sqflite_common/doc/method_call_protocol.md`.
* If the implementation is a Dart-side `DatabaseFactory` (ffi, web,
  in-memory), assign it with `SqflitePlatform().databaseFactory = factory`
  or directly `databaseFactory = factory` from
  `package:sqflite_common/sqflite.dart`. The factory must be a real sqflite
  implementation: build it with the `SqfliteDatabaseFactoryMixin` /
  `buildDatabaseFactory(invokeMethod: ...)` helpers that `sqflite_common`
  exports for implementers (`package:sqflite_common/src/mixin/import_mixin.dart`,
  an implementation import) so that `openDatabase`, versioning, transactions
  and batches reuse the shared Dart logic. A plain class implementing
  `DatabaseFactory` is rejected by the setter.
* `SqflitePlatform().databaseFactory` (instance getter) returns the current
  global factory; `SqflitePlatform.databaseFactoryMethodChannel` returns the
  method channel one.
* Errors: the method channel factory converts a `PlatformException` whose
  `code` is `sqlite_error` into a `DatabaseException`; native code must use
  that code and pass the SQL and arguments in `details` so
  `DatabaseException.toString()` and `getResultCode()` work.
* Keep the package Flutter-only concerns (channels, `registerWith`) here;
  put anything reusable in `sqflite_common`.

## Examples

### pubspec.yaml of an implementation package

```yaml
name: sqflite_myos
dependencies:
  flutter:
    sdk: flutter
  sqflite_platform_interface: ">=2.4.1 <4.0.0"
  sqflite_common: ">=2.5.9 <4.0.0"

flutter:
  plugin:
    implements: sqflite
    platforms:
      myos:
        pluginClass: SqflitePlugin
        dartPluginClass: SqfliteMyOs
```

### Method channel implementation

```dart
import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

class SqfliteMyOs extends SqflitePlatform {
  /// Called by Flutter at startup (dartPluginClass).
  static void registerWith() {
    SqflitePlatform.initWithDatabaseFactoryMethodChannel();
  }
}
```

### Registering a Dart-side factory

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

/// [factory] must come from an sqflite implementation (for example
/// databaseFactoryFfi from sqflite_common_ffi, or one built with
/// buildDatabaseFactory).
void registerDartFactory(DatabaseFactory factory) {
  SqflitePlatform().databaseFactory = factory;
}
```

### Reading the factory from the interface

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

Future<Database> openThroughInterface(String path) {
  final DatabaseFactory factory = SqflitePlatform().databaseFactory;
  return factory.openDatabase(path);
}
```

## Common mistakes

* Depending on `sqflite_platform_interface` from an application; apps use
  `package:sqflite` (or `sqflite_common` + an implementation).
* Forgetting `dartPluginClass` in the pubspec, so `registerWith()` never runs
  and `openDatabase` throws `StateError: databaseFactory not initialized`.
* Assigning a custom class that merely `implements DatabaseFactory`:
  `ArgumentError: Unsupported sqflite factory`.
* Returning errors with a code other than `sqlite_error` from native code;
  they surface as raw `PlatformException`s instead of `DatabaseException`.

## More

Default implementations to copy from: `sqflite_android` (Kotlin/Java,
`SqfliteAndroid`) and `sqflite_darwin` (Objective-C, `SqfliteDarwin`,
`sharedDarwinSource`). App-level usage: the `sqflite` package skills.
