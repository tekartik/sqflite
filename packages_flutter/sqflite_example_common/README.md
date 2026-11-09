# sqflite_example_common

The example app shared by the sqflite example and test apps
(`sqflite/example`, `sqflite_android/example`, `sqflite_darwin/example`, the
test apps of this repository): a menu of test pages (raw SQL, open and
versions, value types, batches, slow operations, a todo example, exceptions,
experiments, manual tests) running on the global sqflite `databaseFactory`.
Each page runs its tests and shows them green or red.

It is not on pub.dev. To learn the API, start with the
[sqflite README](https://github.com/tekartik/sqflite/blob/master/sqflite/README.md);
`lib/todo_test_page.dart` holds a small `TodoProvider` example. The automated
version of these tests is
[sqflite_common_test](https://github.com/tekartik/sqflite/tree/master/sqflite_common_test).

## Getting started

Run it on the Linux desktop with ffi (the Linux runner is included):

```sh
flutter run -d linux --target=lib/main_ffi.dart
```

For Windows or macOS, add the runner first (`flutter create --platforms=windows .`).

From your own example app, as a git dependency:

```yaml
dependencies:
  sqflite_example_common:
    git:
      url: https://github.com/tekartik/sqflite
      path: packages_flutter/sqflite_example_common
```

```dart
import 'package:sqflite_example_common/main.dart';

void main() {
  // The sqflite plugin sets the global databaseFactory on Android, iOS and
  // macOS; elsewhere set it before (see lib/main_ffi.dart).
  mainExampleApp();
}
```

## What it provides

* `mainExampleApp()`: runs `SqfliteExampleApp`.
* `extraRoutes`: pages of your app added to the menu (set it before
  `mainExampleApp()`).
* `supportsCompatMode`: set it to true for the native plugin (old behaviours
  some pages check).
* `platformHandler` (`package:sqflite_example_common/database/database.dart`):
  the file helpers of the pages, `dart:io` by default; set your own on the
  web.
