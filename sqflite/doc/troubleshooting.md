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
    language:
    strict-casts: true
    strict-inference: true
```

# Common issues

## Cast error

```
Unhandled exception: type '_InternalLinkedHashMap' is not a subtype of type 'Map<String, Object?>'
 where
  _InternalLinkedHashMap is from dart:collection
  Map is from dart:core
  String is from dart:core
```

Make sure you create object of type `Map<String, Object?>` and not simply `Map` for records you
insert and update. The option `language: strict-casts: false` explained above helps to find such issues

## MissingPluginException

This error is typically a build/setup error after adding the dependency.

- Try all the steps defined at the top of the documents
- Make sure you stop the current running application if any (hot restart/reload won't work)
- Force a `flutter packages get`
- Try to clean your build folder `flutter clean`
- On iOS, you can try to force a `pod install` / `pod update`
- Follow the [using package flutter guide](https://flutter.dev/docs/development/packages-and-plugins/using-packages)
- Search for [other bugs in flutter](https://github.com/flutter/flutter/search?q=MissingPluginException&type=Issues)
  like this, other people face the same issue with other plugins so it is likely not sqflite related

Advanced checks:

- If you are using sqflite in a FCM Messaging context, you might need
  to [register the plugin earlier](https://github.com/tekartik/sqflite/issues/446).
- if the project was generated a long time ago (2019), you might have to follow
  the [plugin migration guide](https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration)
- Check the GeneratedPluginRegistrant file that flutter run should have generated in your project contains
  a line registering the plugin.

  Android:
  ```java
  SqflitePlugin.registerWith(registry.registrarFor("com.tekartik.sqflite.SqflitePlugin"));
  ```
  iOS:
  ```objective-c
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
  ```
- Check MainActivity.java (Android) contains a call to
  GeneratedPluginRegistrant asking it to register itself. This call should be made from the app
  launch method (onCreate).
  ```java
  public class MainActivity extends FlutterActivity {
      @Override
      protected void onCreate(Bundle savedInstanceState) {
          super.onCreate(savedInstanceState);
          GeneratedPluginRegistrant.registerWith(this);
      }
  }
  ```
- Check AppDelegate.m (iOS) contains a call to
  GeneratedPluginRegistrant asking it to register itself. This call should be made from the app
  launch method (application:didFinishLaunchingWithOptions:).
  ```objective-c
  - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
  }
  ```
- If it happens to Android release mode, make sure to [remove shrinkResources
  true and minifyEnabled true lines in build.gradle](https://github.com/tekartik/sqflite/issues/452#issuecomment-655602329)
  to solve the problem.

Before raising this issue, try adding another well established plugin (the simplest being
`path_provider` or `shared_preferences`) to see if you get the error here as well.

## Warning database has been locked for...

If you get this output in debug mode:

> Warning database has been locked for 0:00:10.000000. Make sure you always use the transaction object for database
> operations during a transaction

One common mistake is to use the db object in a transaction:

```dart
await db.transaction((txn) async {
  // DEADLOCK HERE
  await db.insert('my_table', {'name': 'my_name'});
});
```

...instead of using the correct transaction object (below named `txn`):

```dart
await db.transaction ((txn) async {
  // Ok!
  await txn.insert('my_table', {'name': 'my_name'});
});
```

## Debugging SQL commands

A quick way to view SQL commands printed out is to call before opening any database

```dart
await Sqflite.devSetDebugModeOn(true);
```

This call is on purpose deprecated to force removing it once the SQL issues has been resolved.

## iOS build issue

### General

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

In the worst case, you can also re-create your ios project by deleting the ios/folder and running `flutter create .`

### Undefined symbols for architecture armv7

You might encounter this error on old projects or sometimes when sqflite is included by another dependency.

I have not found a solution to fix this in sqflite itself so the fix has to be done in your application Podfile
(you can just append this at the end of the `Podfile` file)

```
post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS"] = "armv7"
  end
end
```

You might also want to enforce a SDK version, sometimes just declaring `platform :ios, '9.0'` is not sufficient. Below
is an example

```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
```

Since Flutter templates change over time for new sdk, you might sometimes try to delete the ios folder and re-create
your project.

### XCode 14 support

You might likely get the following error:

```
Error (Xcode): File not found: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc/libarclite_iphonesimulator.a
```

See: https://developer.apple.com/forums/thread/728021

Xcode 14 only supports building for a deployment target of iOS 11.

Here as well you need to enforce the deployment target until I find a better way
as the FMDB dependency is no longer actively maintained.

In your application Podfile inside the post_install section where you have this in the
app template:

```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

you need to have
(11 is used here, but you might want to specify a higher platform):

```
post_install do |installer|

  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
      end
    end
  end

  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

### Module 'FMDB' not found

Versions after v2.3.2 don't include FMDB anymore. You can remove it from your Podfile.

Before v2.3.2 and after v2.2.1, you might encounter `Module 'FMDB' not found` on old projects.

You need to add `use_frameworks!` in your Podfile:

```
target 'Runner' do
  # Needed since v2.2.1-1
  # In newly create project, this is set but it is not
  # always the case on older projects
  use_frameworks!
  ...
end
```

### Missing signature

When uploading to App Store Connect, you might get the following warning:

> ITMS-91065: Messing signature - Your app includes “Frameworks/sqflite.framework/sqflite”,
> which includes sqflite, an SDK that was identified in the documentation as a 
> privacy-impacting third-party SDK

Relevant issues:
- https://github.com/tekartik/sqflite/issues/1129
- https://github.com/flutter/flutter/issues/148300

This might happen if you use frameworks (see https://docs.flutter.dev/add-to-app/ios/project-setup).

Thanks to [@swaraj-rawal](https://github.com/swaraj-raw) for the solution:

So first we need to manually sign the xcFramework using the below command:

```
codesign --timestamp -v -f --sign "<Identity> (**********)" sqflite.xcframework
```

use command to check the signature details of the xcFramework:

```
codesign -dv sqflite.xcframework
```

then use command:
`codesign -vv sqflite.xcframework` to check the integrity of the xcFramework, like to find if any error is there in the signature or not.
If all is okay then you'll see this message after using -vv command.
```
$ codesign -vv sqflite.xcframework
sqflite.xcframework: valid on disk
sqflite.xcframework: satisfies its Designated Requirement
```

All set, you're good to go with archiving your iOS app.

Note: There is a .dSYM file associated with the xcFramework Signature, make your .gitignore file is ignoring that .dSYM file.

## Runtime exception

### Json1 extension

```
DatabaseException: DatabaseException(no such function: JSON_OBJECT)
```

I could not find the details of what each built-in version includes (for
example the version os SQLite for each Android OS version
here https://developer.android.com/reference/android/database/sqlite/package-summary)
but I doubt any of them include the json1 extension.

json1 extension requires at least of SQLite 3.38.0 (2021-02-09) (https://www.sqlite.org/json1.html)

`sqflite` uses the SQLite available on the platform. It does not ship/bundle any additional SQLite library. You can get the
version using `SELECT sqlite_version()`:

```dart
print((await db.rawQuery('SELECT sqlite_version()')).first.values.first);
```

which should give a version formatted like this:

```
3.22.0
```

Unfortunately the version of SQLite depends on the OS version.

You could get a more recent version using [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi).

You could then add [`sqlite3_flutter_libs`](https://pub.dev/packages/sqlite3_flutter_libs) for ios/android or include your own
sqlite shared library for desktop or mobile (one for each platform).


### Open error

Such error is often reported with something similar to:

```text
SqfliteFfiException(sqlite_error: 14, , open_failed: SqliteException(14): while opening the database, bad parameter or other API misuse, bad parameter or other API misuse (code 21)})
```

Please check and ensure that:
- The database path is correct (please provide it in the bug report, best is to print it out to report it exactly as it is used)
- The parent folder exists (you should create it if it does not exist)
- The parent folder is writable (try to create a file in it if you still get the error).

Solutions:
- Use the `path_provider` package to find the best location for you database (`getDatabasesPath()` is only relevant for Android)
- Build the database path properly (using `join` from the `path` package)
- Create the parent folder if it does not exist

## Error in Flutter web

Look at package [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web) for experimental Web support.

IndexedDB or any solution on top of it should be considered for storage on the Web.

