# Encryption support

Since `sqflite_common_ffi` 2.4.0 (`sqlite3` 3.x), the SQLite library is selected
with build hooks in your application `pubspec.yaml`. `sqlite3` provides 2
encrypted builds for every platform:
* `sqlite3mc`: [SQLite3MultipleCiphers](https://github.com/utelle/SQLite3MultipleCiphers)
* `sqlcipher`: [SQLCipher](https://www.zetetic.net/sqlcipher/) community edition (links OpenSSL on Windows, Linux and Android)

Check their licenses. More options in the
[sqlite3 hook documentation](https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md).

`pubspec.yaml`:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc # or sqlcipher
```

Then set the password with `PRAGMA key` as the first statement, in
`onConfigure`:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openEncryptedDatabase(String path, String password) {
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        // First statement on the connection.
        await db.execute("PRAGMA key = '$password'");
      },
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
      },
    ),
  );
}
```

Opening an encrypted database with a wrong password fails with a
`DatabaseException` (`file is not a database`).

## Before 2.4.0 (sqlite3 v2)

The SQLCipher library had to be found and loaded in an `ffiInit` function with
`open.overrideForAll` from `package:sqlite3/open.dart` (this API no longer
exists in `sqlite3` v3), as described
[here](https://github.com/davidmartos96/sqflite_sqlcipher/issues/28). See this
page in the git history of this repository for the full example.
