# Dev tips

## Extract SQLite database on Android

In Android Studio (> 3.0.1)
* Open `Device File Explorer via View > Tool Windows > Device File Explorer`
* Go to `data/data/[PACKAGE_NAME]/app_flutter`, where PACKAGE_NAME is the name of your package.
  Location might depends how the path was specified (assuming here that are using path_provider to get its direction)
* Right click on the database and select Save As.... Save it anywhere you want on your PC.