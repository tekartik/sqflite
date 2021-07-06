# Encryption support

Encryption on Desktop is supported using the following trick as described [here](https://github.com/davidmartos96/sqflite_sqlcipher/issues/28):

Basically you have to find and load the proper SQL cipher library. Then you can set the password
using `PRAGMA KEY='password'`

Below is an example to open a database using the password 1234. Thanks to David Martos (who also maintain)

```dart
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

Future<void> main(List<String> arguments) async {
  final dbFactory = createDatabaseFactoryFfi(ffiInit: ffiInit);

  final db = await dbFactory.openDatabase(
    Directory.current.path + "/db_pass_1234.db",
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        // This is the part where we pass the "password"
        await db.rawQuery("PRAGMA KEY='1234'");
      },
      onCreate: (db, version) async {
        db.execute("CREATE TABLE t (i INTEGER)");
      },
    ),
  );
  print(await db.rawQuery("PRAGMA cipher_version"));
  print(await db.rawQuery("SELECT * FROM sqlite_master"));
  print(db.path);
  await db.close();
}

void ffiInit() {
  open.overrideForAll(sqlcipherOpen);
}

DynamicLibrary sqlcipherOpen() {
  // Taken from https://github.com/simolus3/sqlite3.dart/blob/e66702c5bec7faec2bf71d374c008d5273ef2b3b/sqlite3/lib/src/load_library.dart#L24
  if (Platform.isLinux || Platform.isAndroid) {
    try {
      return DynamicLibrary.open('libsqlcipher.so');
    } catch (_) {
      if (Platform.isAndroid) {
        // On some (especially old) Android devices, we somehow can't dlopen
        // libraries shipped with the apk. We need to find the full path of the
        // library (/data/data/<id>/lib/libsqlite3.so) and open that one.
        // For details, see https://github.com/simolus3/moor/issues/420
        final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();

        // app id ends with the first \0 character in here.
        final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
        final appId = String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));

        return DynamicLibrary.open('/data/data/$appId/lib/libsqlcipher.so');
      }

      rethrow;
    }
  }
  if (Platform.isIOS) {
    return DynamicLibrary.process();
  }
  if (Platform.isMacOS) {
    // TODO: Unsure what the path is in macos
    return DynamicLibrary.open('/usr/lib/libsqlite3.dylib');
  }
  if (Platform.isWindows) {
    // TODO: This dll should be the one that gets generated after compiling SQLcipher on Windows
    return DynamicLibrary.open('sqlite3.dll');
  }

  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}
```

