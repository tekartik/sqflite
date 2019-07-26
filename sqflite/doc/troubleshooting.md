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

## MissingPluginException

This error is typically a build/setup error after adding the dependency.

- Try all the steps defined at the top of the documents
- make sure you stop the current running application if any
- force a `flutter packages get`
- try to clean your build folder `flutter clean`
- on iOS, you can try to force a `pod install` / `pod update`

Advanced checks:
- the GeneratedPluginRegistrant file that flutter run should have generated in your project contain
  a line registering the plugin
- (iOS) AppDelegate.m (iOS) or MainActivity.java (Android) contain a call to 
  GeneratedPluginRegistrant asking it to register itself. Those calls should be made from the app
  launch method (application:didFinishLaunchingWithOptions: on iOS, onCreate on Android).

Before raising this issue, try adding another well established plugin (the simplest being 
`path_provider` or `shared_preferences`) to see if you get the error here as well.

## Debugging SQL commands

A quick way to view SQL commands printed out is to call before opening any database

```dart
await Sqflite.devSetDebugModeOn(true);
```

This call is on purpose deprecated to force removing it once the SQL issues has been resolved.

## iOS build issue

I'm not an expert on iOS so it is hard for me reply to issues you encounter especially when you integrate
into your app. Good if you can validate that you have no issue with other plugin such as `path_provider` and that
the example app work with your setup.

I test mainly with the beta channel. Good if you can try if the example work with your setup

```bash
# Switch to beta
flutter channel beta
flutter upgrade

# Get the project and build/run the example
git clone https://github.com/tekartik/sqflite.git
cd sqflite/example

flutter packages get
# build for iOS
flutter build ios
# run!
flutter run
```

If you want to use master, please try the following to see if it works with your setup

```bash
# Switch to master
flutter channel master
flutter upgrade

# Get the project and build/run the example
git clone https://github.com/tekartik/sqflite.git
cd sqflite/example

flutter packages get
# build for iOS
flutter build ios
# run!
flutter run
```