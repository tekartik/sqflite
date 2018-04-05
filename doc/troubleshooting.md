# Troubleshooting

If you ran into build/runtime issues, please try the following:

* Update flutter to the latest version (`flutter upgrade`)
* Update sqflite dependencies to the latest version in your `pubspec.yaml` 
(`sqflite >= X.Y.Z`)
* Update dependencies (`flutter packages upgrade`)
* try `flutter clean`
* Try deleting the flutter cache folder (which will 
downloaded again automatically) from your flutter installation folder `$FLUTTER_TOP/bin/cache`

# Recommendations

* Enable strong-mode
* Disable implicit casts

Sample `analysis_options.yaml` file:

```
analyzer:
  strong-mode:
    implicit-casts: false
```

# Common issues

## Cast error

```
Unhandled exception: type '_InternalLinkedHashMap' is not a subtype of type 'Map<String, dynamic>'
 where
  _InternalLinkedHashMap is from dart:collection
  Map is from dart:core
  String is from dart:core
```

Make sure you create object of type `Map<String, dynamic>` and not simply `Map` for records you
insert and update. The option `implicit-casts: false` explained above helps to find such issues

## Debugging SQL commands

A quick way to view SQL commands printed out is to call before opening any database

```dart
await Sqflite.devSetDebugModeOn(true);
```

This call is on purpose deprecated to force removing it once the SQL issues has been resolved.