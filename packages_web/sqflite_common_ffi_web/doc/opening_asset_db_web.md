## Import an asset database on the web

On the web, the database is not a regular file so the current solution for importing an existing database (asset or url)
is to use the `databaseFactory.writeDatabaseBytes()` method.

The following snippet shows how to import an asset database on the web. It should also work on io (ios/android/desktop) although it might involve another
step such as creating the destination directory.

Check [opening_asset_db.md](../../../sqflite/doc/opening_asset_db.md) for more information on the overall strategy for importing a database and io support.

```dart
// Copy from asset to a database file.
final data = await rootBundle.load(url.join('assets', 'example.db'));
final bytes =
  data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
await databaseFactory.writeDatabaseBytes(path, bytes);
```