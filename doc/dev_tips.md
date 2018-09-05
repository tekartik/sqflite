# Dev tips

## Debugging

Unfortunately at this point, we cannot use sqflite in unit test.
Here are some debugging tips when you encounter issues:

### Turn on SQL console logging

Temporarily turn on SQL logging on the console by adding the following call in your code before opening the first database

````dart
Sqflite.devSetDebugModeOn(true);
````

This call is `deprecated` on purpose to prevent keeping it in your app

### List existing tables

This will print all existing tables, views, index, trigger and their schema (`CREATE` statement).
You might see some system table (`sqlite_sequence` as well as `android_metadata` on Android)


````dart
print(await db.query("sqlite_master"));
````

### Dump a table content

you can simply dump an existing table content:

````dart
print(await db.query("my_table"));
````


## Extract SQLite database on Android

In Android Studio (> 3.0.1)
* Open `Device File Explorer via View > Tool Windows > Device File Explorer`
* Go to `data/data/<package_name>/databases`, where `<package_name>` is the name of your package.
  Location might depends how the path was specified (assuming here that are using `getDatabasesPath` to get its base location)
* Right click on the database and select Save As.... Save it anywhere you want on your PC.