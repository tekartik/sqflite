# sqflite_platform_interface example

This package is used by the sqflite platform implementations, not by apps
(apps use [sqflite](https://pub.dev/packages/sqflite)).

## A platform implementation using the method channel

`lib/sqflite_myos.dart` of a `sqflite_myos` plugin package, whose native code
speaks the sqflite method channel protocol (channel `com.tekartik.sqflite`):

```dart
import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

/// sqflite implementation for "myos".
class SqfliteMyOs extends SqflitePlatform {
  /// Called by Flutter before `main()` (the `dartPluginClass`).
  static void registerWith() {
    // Sets the method channel factory as the global sqflite databaseFactory,
    // unless one is already set.
    SqflitePlatform.initWithDatabaseFactoryMethodChannel();
  }
}
```

Its `pubspec.yaml`:

```yaml
name: sqflite_myos
environment:
  sdk: ^3.12.0
  flutter: ">=3.44.0"
dependencies:
  flutter:
    sdk: flutter
  sqflite_common: ">=2.5.9 <4.0.0"
  sqflite_platform_interface: ">=2.4.3 <4.0.0"

flutter:
  plugin:
    implements: sqflite
    platforms:
      myos:
        pluginClass: SqflitePlugin
        dartPluginClass: SqfliteMyOs
```

## The app side

Nothing specific: on that platform the app code using `sqflite` works as is.

```dart
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  var db = await openDatabase(
    'my.db',
    version: 1,
    onCreate: (db, version) =>
        db.execute('CREATE TABLE Note (id INTEGER PRIMARY KEY, text TEXT)'),
  );
  await db.insert('Note', {'text': 'hello'});
  print(await db.query('Note'));
  await db.close();
}
```

Real implementations:
[sqflite_android](https://github.com/tekartik/sqflite/tree/master/sqflite_android)
and
[sqflite_darwin](https://github.com/tekartik/sqflite/tree/master/sqflite_darwin).
