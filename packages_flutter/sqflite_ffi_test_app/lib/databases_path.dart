import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// A `databases` folder in the application support directory, on every
/// platform (not web).
///
/// A private, writable application folder that the user does not see:
/// - Android: `/data/user/0/<package>/files/databases`
/// - iOS: `<container>/Library/Application Support/databases`
/// - macOS: `~/Library/Containers/<bundle id>/Data/Library/Application Support/<bundle id>/databases`
///   (sandboxed app)
/// - Linux: `~/.local/share/<application id>/databases`
/// - Windows: `%APPDATA%\<company>\<product>\databases`
///
/// This is the one used by this application.
Future<String> appDatabasesPath() async {
  var supportDir = await getApplicationSupportDirectory();
  return join(supportDir.path, 'databases');
}

/// The folders used by the native sqflite plugin on Android, iOS and macOS,
/// to keep the existing databases of an app moving from sqflite to
/// sqflite_ffi; [appDatabasesPath] on Linux and Windows.
///
/// - Android: `/data/user/0/<package>/databases`
/// - iOS, macOS: the Documents directory (on iOS it is backed up and can be
///   visible in the Files app; on a non sandboxed macOS app it is the user
///   Documents folder)
Future<String> sqflitePluginDatabasesPath() async {
  if (Platform.isAndroid) {
    // The files directory and the databases directory share the same parent,
    // the application data directory.
    var supportDir = await getApplicationSupportDirectory();
    return join(dirname(supportDir.path), 'databases');
  } else if (Platform.isIOS || Platform.isMacOS) {
    return (await getApplicationDocumentsDirectory()).path;
  }
  return await appDatabasesPath();
}
