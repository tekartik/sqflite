# Opening a database

## finding a location path for the database

A database is a file identified by a path. `getDatabasesPath()` returns the
default folder of the current database factory:

| Factory | `getDatabasesPath()` |
|---|---|
| `sqflite` on Android | `/data/data/<package>/databases` (also shown as `/data/user/0/<package>/databases`), as recommended on Android |
| `sqflite` on iOS and macOS | the Documents directory |
| `sqflite_common_ffi` (Windows, Linux, Dart VM, tests) | `.dart_tool/sqflite_common_ffi/databases` in the current directory: fine for tests and scripts, not for an installed application |
| `sqflite_common_ffi_web` | `/`: on the web a path is only a name in the browser storage |

```dart
var databasesPath = await getDatabasesPath();
var path = join(databasesPath, dbName);
```

`join` is from the [path](https://pub.dev/packages/path) package.

On iOS, the Library directory is often a better location (not visible to the
user). In a desktop application, use a folder of the application such as the
application support directory. Both come from the
[path_provider](https://pub.dev/packages/path_provider) package. You can then
either use absolute paths or change the default folder once, before opening any
database:

```dart
var dir = await getApplicationSupportDirectory(); // path_provider
await databaseFactory.setDatabasesPath(join(dir.path, 'databases'));
```

The parent directory of the database file is created when opening it (in
read-write mode), you don't need to create it yourself.

## Opening

A SQLite database is a file in the file system identified by a path. If relative, this path is relative to the path
obtained by `getDatabasesPath()`.

```dart
var db = await openDatabase('my_db.db');
```

Open a database once and keep the `Database` object for the lifetime of your
application (see [Prevent database locked issue](#prevent-database-locked-issue)).

## Read-write

Opening a database in read-write mode is the default. One can specify a version to perform
migration strategy, can configure the database and its version.

The optional callbacks are called in this order:
1. `onConfigure`
2. `onCreate` or `onUpgrade` or `onDowngrade` (only when `version` is specified
   and differs from the version of the database)
3. `onOpen`

### Configuration

`onConfigure` is the first optional callback called. It allows to perform database initialization
such as supporting cascade delete. It is called at each open, before any
other callback.

```dart
Future<void> onConfigure(Database db) async {
  // Add support for cascade delete
  await db.execute('PRAGMA foreign_keys = ON');
}

var db = await openDatabase(path, onConfigure: onConfigure);
```

### Preloading data

You might want to preload you database when opened the first time. You can either
* [Import an existing SQLite file](opening_asset_db.md) checking first whether the database file exists or not
* Populate data during `onCreate`:

```dart
Future<void> onCreate(Database db, int version) async {
  // Database is created, create the table
  await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
  // populate data
  await db.insert('Test', {'value': 'initial value'});
}

// Open the database, specifying a version and an onCreate callback
var db = await openDatabase(path, version: 1, onCreate: onCreate);
```

### Migration

To handle database upgrades (schema changes), there is a basic version mechanism
similar to the Android API. While `getVersion` and `setVersion` are exposed,
there should not be used and instead, migrations should be performed when opening
the database.

`onCreate`, `onUpgrade`, and `onDowngrade` are called when a `version` is
specified. If the database does not exist, `onCreate` is called. If `onCreate`
is not defined, `onUpgrade` is called instead with `oldVersion` having value 0.
If the database exists and the new version is higher than the current version,
`onUpgrade` is called. Inversely, if the new version is lower than the current
version, `onDowngrade` is called. Try to avoid this by always incrementing the
database version. For the downgrade case, a special `onDatabaseDowngradeDelete`
callback exist that will simply delete the database and call `onCreate` to
create it.

These 3 callbacks are called within a transaction just before the version is set on the database.
Use the `db` object they receive directly (do not start a transaction in them)
and await every call: the version is saved when the callback completes.

`onCreate` is only called when the database does not exist yet. Changing your
`onCreate` code has no effect on an existing database: increment the `version`
and handle the change in `onUpgrade`.

```dart
Future<void> onCreate(Database db, int version) async {
  // Database is created, create the table
  await db.execute(
    'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT, name TEXT)',
  );
}

Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Database version is updated, alter the table
    await db.execute('ALTER TABLE Test ADD name TEXT');
  }
}

// Special callback used for onDowngrade here to recreate the database
var db = await openDatabase(
  path,
  version: 2,
  onCreate: onCreate,
  onUpgrade: onUpgrade,
  onDowngrade: onDatabaseDowngradeDelete,
);
```

See a [complete migration example](migration_example.md)

### Post open callback

For convenience, `onOpen` is called after the database version is set and before `openDatabase` returns.

```dart
Future<void> onOpen(Database db) async {
  // Database is open, print its version
  print('db version ${await db.getVersion()}');
}

var db = await openDatabase(path, onOpen: onOpen);
```

## Read-only

```dart
// open the database in read-only mode
var db = await openReadOnlyDatabase(path);
```

In read-only mode (`openReadOnlyDatabase(path)` or `openDatabase(path, readOnly: true)`):
* the database file must exist, opening a missing file fails,
* `onConfigure` and `onOpen` are still called,
* do not specify a `version`: if it differs from the version of the file, the
  migration callback is called and saving the new version fails (the database
  is read-only), so the open fails,
* any write fails (`DatabaseException.isReadOnlyError()`).

## Handle corruption

Android and iOS handles corruption in a different way:
* on iOS, it fails on first access to the database
* on Android, the existing file is removed (Android's default behavior for a
  read-write open; a read-only open keeps the file and fails on first access).

I don't know yet how to make it consistent without breaking the existing behavior.

It seems that one way to check if a file is a valid database file is to open it in read-only 
and check its version (i.e. sqlite/iOS fails un-consistently on first access of a non-sqlite database).
Before making this a top-level function, more tests would be needed to validate the behavior.

```dart
/// Check if a file is a valid database file
///
/// An empty file is a valid empty sqlite file
Future<bool> isDatabase(String path) async {
  Database? db;
  var isDatabase = false;
  try {
    db = await openReadOnlyDatabase(path);
    await db.getVersion();
    isDatabase = true;
  } catch (_) {
  } finally {
    await db?.close();
  }
  return isDatabase;
}
```

## Prevent database locked issue

It is strongly suggested to open a database only once. By default a database is open as
a single instance (`singleInstance: true`). i.e. re-opening the same file is safe and it 
will give you the same database:
* the callbacks given to the second `openDatabase` call are ignored (the database is
  already open),
* closing the database closes it for every place holding it.

This also applies to the in-memory database (`inMemoryDatabasePath`, `:memory:`):
opening it twice without closing it gives the same database, and the next open
after a close gives a new empty database. Use `singleInstance: false` to get a
private in-memory database at each open.

```dart
var db1 = await openDatabase(inMemoryDatabasePath);
var db2 = await openDatabase(inMemoryDatabasePath);
// Same instance, same in-memory database
assert(identical(db1, db2));
// A private in-memory database
var db3 = await openDatabase(inMemoryDatabasePath, singleInstance: false);
await db3.close();
// Closes db1 and db2
await db1.close();
```

If you open the same database file multiple times using `singleInstance: false`, you might encounter (at least on Android):

    android.database.sqlite.SQLiteDatabaseLockedException: database is locked (code 5)

On the web (`sqflite_common_ffi_web`), opening the same database multiple times using `singleInstance: false`
is not supported and throws an `ArgumentError`: the web virtual file system has no locking between
connections and a second connection could corrupt the database.
    
Let's consider the following helper class

```dart
class Helper {
  Helper(this.path);

  final String path;
  Database? _db;

  Future<Database> getDb() async {
    _db ??= await openDatabase(path);
    return _db!;
  }
}
```

Since `openDatabase` is async, there is a race condition risk where openDatabase
might be called twice. You could fix this by keeping the `Future`:

```dart
class Helper {
  Helper(this.path);

  final String path;
  Future<Database>? _db;

  Future<Database> getDb() {
    _db ??= openDatabase(path);
    return _db!;
  }
}
```

If you have some lengthy operations after `openDatabase` before considering it ready for the user
you should protect your code (put here in a private `_initDb()` method from concurrent access:

```dart
class Helper {
  Helper(this.path);

  final String path;
  Future<Database>? _db;

  Future<Database> getDb() => _db ??= _initDb();

  // Guaranteed to be called only once.
  Future<Database> _initDb() async {
    final db = await openDatabase(path);
    // do "tons of stuff in async mode"
    return db;
  }
}
```


## Solving exceptions

If you get exception when opening a database:
- check the [troubleshooting](troubleshooting.md) section
- Make sure the database path points to an existing database (or nothing) and
  not to a file which is not a sqlite database
- Handle any expected exception in the open callbacks (onCreate/onUpgrade/onConfigure/onOpen)
- On Windows, Linux and the web, make sure the database factory is set
  (`databaseFactory not initialized` error), see [desktop](desktop_support.md)
  and [web](web_support.md) support.
