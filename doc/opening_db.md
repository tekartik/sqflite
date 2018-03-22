# Opening a database

## finding a location path for the database

Sqflite does not provide any location strategy. Currently the way it is mostly used is using
the `path_provider` plugin to find a location to write the sqlite database file

```dart
var documentsDirectory = await getApplicationDocumentsDirectory();
var path = join(documentsDirectory.path, dbName);

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

### Migration

`onCreate`, `onUpdate`, `onDowngrade` is called if a `version` is specified. If the database does 
not exist, `onCreate` is called. If the new version requested is higher, `onUpdate` is called, otherwise
(try to avoid this by always incrementing the database version), `onDowngrade` is called. For this
later case, a special `onDowngradeDatabaseDelete` callback exist that will simply delete the database
and call `onCreate` to create it.

These 3 callbacks are called within a transaction just before the version is set on the database.


```dart
_onCreate(Database db, int version) async {
  // Database is created, delete the table
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