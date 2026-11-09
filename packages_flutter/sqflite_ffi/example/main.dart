import 'package:flutter/widgets.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

/// Opens an in memory database and shows the SQLite version.
///
/// Add sqflite_ffi to a Flutter app (`flutter pub add sqflite_ffi`) and use
/// this as its `lib/main.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The global databaseFactory was set by sqflite_ffi at startup; the
  // factory can also be used directly: sqfliteDatabaseFactoryFfi.
  var db = await openDatabase(inMemoryDatabasePath);
  var rows = await db.rawQuery('SELECT sqlite_version() AS version');
  await db.close();
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('SQLite ${rows.first['version']}')),
    ),
  );
}
