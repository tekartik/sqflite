# sqflite_example_android_wal

Android test app with WAL enabled for every database
(`com.tekartik.sqflite.wal_enabled` in `AndroidManifest.xml`), unlike the
other test apps. Its android folder is checked in for that reason.

Run the sqflite example pages (`sqflite_example_common`) on an Android
device or emulator:

```bash
flutter run
```

Run the WAL regression scenario of issue
[#1204](https://github.com/tekartik/sqflite/issues/1204) (update, delete and
insert results in WAL mode), results in the `flutter run` console:

```bash
flutter run -t test/update_count_issue_wal_test_main.dart
```
