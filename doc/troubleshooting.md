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