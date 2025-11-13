import 'package:sqlite3/sqlite3.dart';

/// Windows specific sqflite3 initialization.
///
/// This code is only provided for reference. See package [`sqlite3`](https://pub.dev/packages/sqlite3)
/// for more information.
void windowsInit() {
  // Force an open in the main isolate
  // Loading from an isolate seems to break on windows
  sqlite3.openInMemory().close();
}
