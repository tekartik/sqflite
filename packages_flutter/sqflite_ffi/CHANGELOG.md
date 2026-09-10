## 0.1.1

* Add `sqflite-ffi-flutter` agent skill in `skills/`, installable with `dart run skills@ get`

## 0.1.0+1

* Improve documentation

## 0.1.0

* Initial version: ffi database factory (`sqfliteDatabaseFactoryFfi`) sharing
  the sqflite isolate between flutter isolates using `IsolateNameServer`.
* Dart only flutter plugin: `SqfliteFfiPlugin.registerWith()` is called
  automatically at startup and sets `sqfliteDatabaseFactoryFfi` as the default
  database factory (if not already set).
