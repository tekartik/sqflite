# Open an asset database

## Add the asset

* Add the asset in your file system at the root of your project. Typically 
I would create an `assets` folder and put my file in it:
````
assets/examples.db
````

* Specify the asset(s) in your `pubspec.yaml` in the flutter section
````
flutter:
  assets:
    - assets/example.db
````

## Copy the database to your file system

Whether you want a fresh copy from the asset or always copy the asset is up to
you and depends on your usage
* are you modifying the asset database
* do you always want a fresh copy from the asset
* do you want to optimize for performance and size


### Optimizing for performance

For better performance you should copy the asset only once (the first time) then
always try to open the copy

```dart
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

var databasesPath = await getDatabasesPath();
var path = join(databasesPath, "demo_asset_example.db");

// Check if the database exists
var exists = await databaseExists(path);

if (!exists) {
  // Should happen only the first time you launch your application
  print("Creating new copy from asset");

  // Make sure the parent directory exists
  try {
    await Directory(dirname(path)).create(recursive: true);
  } catch (_) {}
    
  // Copy from asset
  ByteData data = await rootBundle.load(url.join("assets", "example.db"));
  List<int> bytes =
  data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  
  // Write and flush the bytes written
  await File(path).writeAsBytes(bytes, flush: true);

} else {
  print("Opening existing database");
}

// open the database
var db = await openDatabase(path, readOnly: true);

```

### Optimizing for size

Even better on iOS you could write a native plugin that get the asset file path
and directly open it in read-only mode. Android does not have such ability

### Always getting a fresh copy from the asset

```dart
var databasesPath = await getDatabasesPath();
var path = join(databasesPath, "demo_always_copy_asset_example.db");

// delete existing if any
await deleteDatabase(path);

// Make sure the parent directory exists
try {
  await Directory(dirname(path)).create(recursive: true);
} catch (_) {}

// Copy from asset
ByteData data = await rootBundle.load(url.join("assets", "example.db"));
List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
await new File(path).writeAsBytes(bytes, flush: true);

// open the database
var db = await openDatabase(path, readOnly: true);
```

### Custom strategy

You might want to have a versioning strategy (not yet part of this project) to only copy the asset db when
it changes in the build system or might also allow the user to modify the database (in this case you must copy it
first).

#### One simple solution

Since issues like 'I updated my asset database but the app still see the old one', I propose a simple solution.

One simple solution is to uses a versioning system using an incremental number. An asset version file stores this number. When the app starts,
it checks the version file currently existing on the file system, compare it to the one in the assets and decide
to copy the asset (the db and the version file) or not.

Let's assume that you have a version file named `db_version_num.txt` in your assets folder.
The content of the file is a single line with the version number.

`db_version_num.txt`
```txt
1
```

along with the database file `my_asset_database.db`

You could have the following code to copy the asset database only if the version number is different:
```dart
/// Copy the asset database if needed and open it.
///
/// It uses an external version file to keep track of the asset version.
Future<Database> copyIfNeededAndOpenAssetDatabase(
    {required String databasesPath,
      required String versionNumFilename,
      required String dbFilename}) async {
  var dbPath = join(databasesPath, dbFilename);

  // First check the currently installed version
  var versionNumFile = File(join(databasesPath, versionNumFilename));
  var existingVersionNum = 0;
  if (versionNumFile.existsSync()) {
    existingVersionNum = int.parse(await versionNumFile.readAsString());
  }

  // Read the asset version
  var assetVersionNum = int.parse(
      (await rootBundle.loadString(url.join('assets', versionNumFilename))).trim());

  // Compare them.
  print('existing/asset: $existingVersionNum/$assetVersionNum');

  // If needed, copy the asset database
  if (existingVersionNum < assetVersionNum) {
    print('copying new version $assetVersionNum');
    // Make sure the parent directory exists
    try {
      await Directory(databasesPath).create(recursive: true);
    } catch (_) {}

    // Copy from asset
    var data = await rootBundle.load(url.join('assets', dbFilename));
    var bytes = Uint8List.sublistView(data);

    // Write and flush the database bytes written
    await File(dbPath).writeAsBytes(bytes, flush: true);
    // Write and flush the version file
    await versionNumFile.writeAsString('$assetVersionNum', flush: true);
  }

  var db = await openDatabase(dbPath);
  return db;
}
```

You can then call this function to open the database:
```dart
var db = await copyIfNeededAndOpenAssetDatabase(
  databasesPath: await getDatabasesPath(),
  // The asset database filename.
  dbFilename: 'my_asset_database.db',
  // The version num.
  versionNumFilename: 'db_version_num.txt');
```

When you want to force updating the asset database, you can simply increment the number in the version file (2, 3...).

### Web support

Check [opening_asset_db_web.md](../../packages_web/sqflite_common_ffi_web/doc/opening_asset_db_web.md) for web support.

## Open it!
````
// open the database
Database db = await openDatabase(path);
````

