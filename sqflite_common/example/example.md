# sqflite_common example

`sqflite_common` contains the API, not SQLite. Write the database code against
a `DatabaseFactory`, then give it the factory of the platform:
`databaseFactory` of [sqflite](https://pub.dev/packages/sqflite) (Flutter on
Android, iOS, macOS), `databaseFactoryFfi` of
[sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) (Windows,
Linux, macOS, Dart VM, unit tests) or `databaseFactoryFfiWeb` of
[sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web).

`lib/note_store.dart` (depends on `sqflite_common` only):

```dart
import 'package:sqflite_common/sqlite_api.dart';

/// Platform independent code: it only needs a [DatabaseFactory].
class NoteStore {
  NoteStore(this.factory, this.path);

  final DatabaseFactory factory;
  final String path;
  Future<Database>? _db;

  /// Opened once, on first use.
  Future<Database> get database => _db ??= factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Note (id INTEGER PRIMARY KEY, content TEXT NOT NULL)',
        );
      },
    ),
  );

  Future<int> add(String content) async {
    var db = await database;
    return db.insert('Note', {'content': content});
  }

  Future<List<String>> list() async {
    var db = await database;
    var rows = await db.query('Note', orderBy: 'id');
    return rows.map((row) => row['content'] as String).toList();
  }

  Future<void> close() async {
    var db = await _db;
    _db = null;
    await db?.close();
  }
}
```

`bin/main.dart`, running on the Dart VM with `sqflite_common_ffi`
(`dart pub add sqflite_common_ffi`, then `dart run bin/main.dart`):

```dart
import 'package:my_package/note_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var store = NoteStore(databaseFactoryFfi, inMemoryDatabasePath);
  await store.add('Hello');
  await store.add('World');
  print(await store.list()); // [Hello, World]
  await store.close();
}
```

In a Flutter app using `sqflite`:

```dart
var store = NoteStore(databaseFactory, join(await getDatabasesPath(), 'notes.db'));
```
