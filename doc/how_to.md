# Sqflite guide

* How to [Open a database](opening_db.md)
* How to [Open an asset database](opening_asset_db.md)
* Solve you [build and runtime issues](troubleshooting.md)
* Some personal [usage recommendations](usage_recommendations.md)

## Development guide

### Check list

* run test
* no warning
* string mode / implicit-casts: false

````
# quick run before commiting

dartfmt -w .
flutter analyze lib test
flutter test

flutter run
flutter run --preview-dart-2

# Using preview dart 2
flutter test --preview-dart-2
````

### Publishing

    flutter packages pub publish
