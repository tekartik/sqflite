# sqflite example

A minimal note list app storing its data in a SQLite database. It runs on
Android, iOS and macOS.

Add the dependency:

```bash
flutter pub add sqflite
```

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

/// Opened once, shared by the whole app.
final Future<Database> database = openDatabase(
  'notes.db', // relative to getDatabasesPath()
  version: 1,
  onCreate: (db, version) => db.execute(
    'CREATE TABLE Note (id INTEGER PRIMARY KEY, content TEXT NOT NULL)',
  ),
);

Future<List<String>> getNotes() async {
  var db = await database;
  var rows = await db.query('Note', orderBy: 'id DESC');
  return rows.map((row) => row['content'] as String).toList();
}

Future<void> addNote(String content) async {
  var db = await database;
  await db.insert('Note', {'content': content});
}

void main() {
  runApp(const MaterialApp(home: NotesPage()));
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late Future<List<String>> _notes = getNotes();

  Future<void> _add() async {
    await addNote('Note ${DateTime.now()}');
    setState(() {
      _notes = getNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: FutureBuilder<List<String>>(
        future: _notes,
        builder: (context, snapshot) {
          var notes = snapshot.data;
          if (notes == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [for (var note in notes) ListTile(title: Text(note))],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Windows, Linux and web

The same code runs on other platforms once the global `databaseFactory` is set
at the start of `main()`, see
[one code base for mobile, desktop and web](https://github.com/tekartik/sqflite/blob/master/sqflite/README.md#one-code-base-for-mobile-desktop-and-web).

## Testing

`flutter test` cannot use the plugin; use `sqflite_common_ffi` as a dev
dependency, see [unit testing](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/testing.md).

## More

* [notepad_sqflite](https://github.com/alextekartik/flutter_app_example/tree/master/notepad_sqflite):
  a complete notepad app working on iOS/Android/Windows/Linux/macOS.
* The `example/lib` folder of this package is the test application of the
  plugin (`flutter run` it to run the plugin tests on a device).
