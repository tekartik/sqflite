import 'package:sqflite/sqflite.dart';

import 'package:sqflite_example_common/database/database.dart';

/// Test compatibility old API.
Future<void> testDebugModeCompat() async {
  //await Sqflite.devSetDebugModeOn(false);
  final path = await initDeleteDb('debug_mode.db');
  final db = await openDatabase(path);
  try {
    // ignore: deprecated_member_use
    final debugModeOn = await Sqflite.getDebugModeOn();
    // ignore: deprecated_member_use
    await Sqflite.setDebugModeOn(true);
    await db.setVersion(1);
    // ignore: deprecated_member_use
    await Sqflite.setDebugModeOn(false);
    // this message should not appear
    await db.setVersion(2);
    // ignore: deprecated_member_use
    await Sqflite.setDebugModeOn(true);
    await db.setVersion(3);
    // restore
    // ignore: deprecated_member_use
    await Sqflite.setDebugModeOn(debugModeOn);
  } finally {
    await db.close();
  }
}
