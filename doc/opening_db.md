# Opening a database

## finding a location path for the database

Sqflite provides a basic location strategy using the databases path on Android and the Documents folder on iOS, as
recommended on both platform. The location can be retrieved using `getDatabasesPath`.

```dart
var databasesPath = await getDatabasesPath();
var path = join(databasesPath, dbName);

// Make sure the directory exists
try {
  await documentsDirectory.create(recursive: true);
} catch (_) {}
```

## Read-write

Opening a database in read-write mode is the default. One can specify a version to perform
migration strategy, can configure the database and its version.

### Configuration


`onConfigure` is the first optional callback called. It allows to perform database initialization
such as supporting cascade delete

```dart
_onConfigure(Database db) async {
  // Add support for cascade delete
  await db.execute("PRAGMA foreign_keys = ON");
}

var db = await openDatabase(path, onConfigure: _onConfigure);

```

### Preloading data

You might want to preload you database when opened the first time. You can either
* [Import an existing SQLite file](opening_asset_db.md) checking first whether the database file exists or not
* Populate data during `onCreate`:


```dart
_onCreate(Database db, int version) async {
  // Database is created, create the table
  await db.execute(
    "CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
  }
  // populate data
  await db.insert(...);
}

// Open the database, specifying a version and an onCreate callback
var db = await openDatabase(path,
    version: 1,
    onCreate: _onCreate);
```
### Migration

`onCreate`, `onUpdate`, `onDowngrade` is called if a `version` is specified. If the database does 
not exist, `onCreate` is called. If the new version requested is higher, `onUpdate` is called, otherwise
(try to avoid this by always incrementing the database version), `onDowngrade` is called. For this
later case, a special `onDowngradeDatabaseDelete` callback exist that will simply delete the database
and call `onCreate` to create it.

These 3 callbacks are called within a transaction just before the version is set on the database.


```dart
_onCreate(Database db, int version) async {
  // Database is created, create the table
  await db.execute(
    "CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
}

_onUpgrade(Database db, int oldVersion, int newVersion) async {
  // Database version is updated, alter the table
  await db.execute("ALTER TABLE Test ADD name TEXT");
}

// Special callback used for onDowngrade here to recreate the database
var db = await openDatabase(path,
  version: 1,
  onCreate: _onCreate,
  onUpgrade: _onUpgrade,
  onDowngrade: onDatabaseDowngradeDelete);
```

### Post open callback

For convenience, `onOpen` is called after the database version is set and before `openDatabase` returns.

```dart
_onOpen(Database db) async {
  // Database is open, print its version
  print('db version ${await db.getVersion()}');
}

var db = await openDatabase(
  path,
  onOpen: _onOpen,
);
```
## Read-only

```dart
// open the database in read-only mode
var db = await openReadOnlyDatabase(path);
```

## Prevent database locked issue

It is strongly suggested to open a database only once.
If you open the same database multiple times, you might encounter (at least on Android):

    android.database.sqlite.SQLiteDatabaseLockedException: database is locked (code 5)
    
Let's consider the following helper class

```dart
class Helper {
  final String path;
  Helper(this.path);
  Database _db;

  Future<Database> getDb() async {
    if (_db == null) {
      _db = await openDatabase(path);
    }
    return _db;
  }
}
```

Since `openDatabase` is async, there is a race condition risk where openDatabase
might be called twice. You could fix this with the following:

```dart
import 'package:synchronized/synchronized.dart';

class Helper {
  final String path;
  Helper(this.path);
  Database _db;
  final _lock = new Lock();

  Future<Database> getDb() async {
    if (_db == null) {
      await _lock.synchronized(() async {
        // Check again once entering the synchronized block
        if (_db == null) {
          _db = await openDatabase(path);
        }
      });
    }
    return _db;
  }
}
```