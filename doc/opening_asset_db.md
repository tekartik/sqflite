# Open an asset database

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

* Copy the database to your file system
````
Directory documentsDirectory = await getApplicationDocumentsDirectory();
String path = join(documentsDirectory.path, "asset_example.db");

// delete existing if any
await deleteDatabase(path);

// Copy from asset
ByteData data = await rootBundle.load(join("assets", "example.db"));
List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
await new File(path).writeAsBytes(bytes);
````

* Open it!
````
// open the database
Database db = await openDatabase(path);
````