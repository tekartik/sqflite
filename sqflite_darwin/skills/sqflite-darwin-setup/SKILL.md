---
name: sqflite-darwin-setup
description: >-
  Use when configuring or troubleshooting the iOS/macOS implementation of
  sqflite (package sqflite_darwin): when to add it explicitly,
  SqfliteDarwin.registerWith, CocoaPods podspec and Swift Package Manager
  support, deployment targets (iOS 12, macOS 10.14), the bundled FMDB fork
  (no FMDB pod), privacy manifest, getDatabasesPath (Documents) vs
  path_provider, read-only opening, deleteDatabase side files,
  SqfliteDarwin.createUnprotectedFolder for locked-device background access,
  result codes, Xcode/Podfile build issues.
---

# sqflite_darwin: iOS and macOS implementation of sqflite

`sqflite_darwin` is the endorsed iOS/macOS implementation of the `sqflite`
federated plugin (one shared Objective-C source tree, `sharedDarwinSource:
true`). Adding `sqflite` pulls it in automatically (`default_package:
sqflite_darwin` for both `ios` and `macos`); `SqfliteDarwin.registerWith()`
installs the method channel `DatabaseFactory` as `databaseFactory` before
`main()`. It links the system SQLite through a bundled, renamed copy of FMDB
(`SqfliteDarwin*` classes), so the SQLite version depends on the OS version.

```yaml
# pubspec.yaml (normal case): nothing darwin specific
dependencies:
  sqflite:
```

## Guidelines

* Add `sqflite_darwin` explicitly only when the app does not depend on
  `sqflite` (for example it codes against `package:sqflite_common` and ships
  iOS/macOS only). Registration is automatic; then use `databaseFactory` /
  `openDatabase` from `package:sqflite_common/sqflite.dart`.
* Requirements: iOS 12.0+, macOS 10.14+ (podspec and `Package.swift`),
  Flutter >= 3.44 / Dart >= 3.12. Both CocoaPods (`sqflite_darwin.podspec`)
  and Swift Package Manager are supported; the privacy manifest
  (`PrivacyInfo.xcprivacy`) is bundled as a resource.
* No `FMDB` pod is needed or used; remove any `pod 'FMDB'` line from the
  app `Podfile` left over from sqflite < 2.3.2 (`Module 'FMDB' not found`).
  After upgrading run `flutter clean` and delete `ios/Podfile.lock` /
  `macos/Podfile.lock`.
* `getDatabasesPath()` returns the app Documents directory. Prefer
  `path_provider` (`getLibraryDirectory()` on iOS, or the application
  support directory) for data the user should not see in Files/iCloud
  backups. A relative path is resolved under Documents.
* The plugin creates the parent directory of a read-write database on open;
  a read-only open (`SQLITE_OPEN_READONLY`) does not, and fails on the first
  access if the file is not a SQLite database (corruption is not auto
  repaired or deleted, unlike Android read-write opens).
* `deleteDatabase(path)` also removes the `-wal`, `-shm` and `-journal`
  files; use it rather than `File.delete`.
* `DatabaseException.getResultCode()` yields the primary SQLite result code
  (for example 19 for a constraint violation) on iOS/macOS, the extended
  code on Android/ffi; write checks that accept both or use
  `isUniqueConstraintError()` and friends.
* Background isolate while the device is locked (push notification,
  background fetch): files created in protected folders are unreadable.
  Create the database inside a folder made with
  `SqfliteDarwin.createUnprotectedFolder(parent, name)` (from
  `package:sqflite/sqflite.dart`, `NSFileProtectionNone`), only for
  non-sensitive data.
* Method channel results on macOS are posted back on the main thread; all
  SQL still runs on a background queue per database.
* App Store `ITMS-91065 Missing signature` when the app embeds
  `sqflite.framework` via add-to-app frameworks: sign the xcframework with
  `codesign --timestamp -v -f --sign "<identity>" sqflite.xcframework`.
* Build failures on old projects: enforce
  `IPHONEOS_DEPLOYMENT_TARGET` (>= 12.0) in the Podfile `post_install`,
  keep `use_frameworks!` in the `Runner` target, or recreate the `ios/`
  folder with `flutter create .`.

## Examples

### iOS/macOS-only app on the pure Dart API

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite_common:
  sqflite_darwin:
```

```dart
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/sqflite.dart';

Future<Database> openAppDb() async {
  // databaseFactory was registered by SqfliteDarwin.registerWith().
  final dir = await getLibraryDirectory();
  return openDatabase(
    join(dir.path, 'app.db'),
    version: 1,
    onCreate: (db, _) =>
        db.execute('CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)'),
  );
}
```

### Database readable while the device is locked (needs package:sqflite)

```dart
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> openUnprotectedDb() async {
  final databasesPath = await getDatabasesPath();
  var dir = databasesPath;
  if (Platform.isIOS) {
    dir = join(databasesPath, 'unprotected');
    if (!Directory(dir).existsSync()) {
      await SqfliteDarwin.createUnprotectedFolder(databasesPath, 'unprotected');
    }
  }
  return openDatabase(join(dir, 'notifications.db'), version: 1,
      onCreate: (db, _) => db.execute('CREATE TABLE Event (id INTEGER PRIMARY KEY)'));
}
```

### Podfile post_install for deployment target issues

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

## Common mistakes

* Keeping `pod 'FMDB'` in the Podfile or expecting FMDB symbols; sqflite
  bundles its own renamed copy.
* Storing user databases in Documents (`getDatabasesPath()`) when they
  should not be exposed or backed up; use `path_provider`.
* Comparing `getResultCode()` to Android extended codes only.
* Opening from a background isolate on a locked device without an
  unprotected folder (`DatabaseException(open_failed)`).

## More

App-level API: the `sqflite` package skills (`sqflite-open-database`,
`sqflite-crud-and-transactions`, `sqflite-testing-and-platforms`). Other
implementation: `sqflite_android`. Interface: `sqflite_platform_interface`.
