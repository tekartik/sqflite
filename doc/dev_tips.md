# Dev tips

## Extract SQLite database on Android

In Android Studio (> 3.0.1)
* Open `Device File Explorer via View > Tool Windows > Device File Explorer`
* Go to `data/data/<package_name>/databases`, where `<package_name>` is the name of your package.
  Location might depends how the path was specified (assuming here that are using `getDatabasesPath` to get its base location)
* Right click on the database and select Save As.... Save it anywhere you want on your PC.