## sqlite3 Troubleshooting

### sqlite3 v2 support

sqlite3 v3 (imported since sqflite_common_ffi 2.4.0+) depends on hooks which can cause some issues (iOS validation, dynamic lib not found).
Until these issues are resolved, you can simply add the following constraint to continue using sqlite3 v2

```yaml
dependencives:
  sqlite3: ^2.9.4
  sqflite_common_ffi: ^2.3.7
```

Make sure to run `flutter clean` if you switch from sqlite3 v3 to v2.

### sqlite3 v3 support

Follow the following issue regarding sqlite3 v3 current issues:
https://github.com/simolus3/sqlite3.dart/issues/336

Make sure to use at least sqflite_common_ffi 2.4.0+ and sqlite3 3.0.0+:

```yaml
dependencies:
  sqlite3: ^3.0.0
  sqflite_common_ffi: ^2.4.0
```

Make sure to run `flutter clean` if you switch from sqlite3 v2 to v3.

Since sqlite3 v3 uses build hooks, make sure that these hooks can run.
For dart (not flutter), you have to run at least once:
```shell
dart run xxxx.dart
```
instead of
```shell
dart xxxx.dart
```

so that build hooks can run.

In my experiments, since IDE like intellij do not run build hooks properly, I had to run once from command line so that 
the build hooks can run and setup the dynamic library. after that, IDE runs (that uses `dart xxx.dart`) work fine.

Build hooks are still a new feature so hopefully these issues will be resolved soon.

## Linux

### Missing `libsqlite3.so` (sqlite3 v2)

This is for sqlite_common_ffi before 2.4.0 that depends on sqlite3 v2.

if you get

```
 SqfliteFfiException(error, Invalid argument(s): Failed to load dynamic library (libsqlite3.so: cannot open shared object file: No such file or directory)}
```

Make sure to install the linux package `sqlite3-dev`. 

```$xslt
sudo apt-get -y install libsqlite3-dev
```

#### Solution for github actions

The issue above might happen when running ubuntu-latest on github actions (since `Ubuntu 24.04.1 LTS`, fine up to `ubuntu-22.04.5`).

You can add the following run step (that works on all platforms as it only performs the install for linux):

```
      ...
      # Setup sqlite3 lib (done for linux only but works safely on all platform)
      - name: Install libsqlite3-dev
        run: |
          dart pub global activate --source git https://github.com/tekartik/ci.dart --git-path ci
          dart pub global run tekartik_ci:setup_sqlite3lib
      ...
```

Or if you know that you are on linux you can simply add:
```
     - run: sudo apt-get -y install libsqlite3-dev
```

For sqflite_common_ffi 2.4.0+ (sqlite3 v3), this should not be required anymore.
