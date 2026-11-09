import 'package:path/path.dart' as p;
// ignore: implementation_imports
import 'package:sqflite_common/src/path_utils.dart'
    show isFileUriDatabasePath, isInMemoryDatabasePath;

/// Resolve a database path the way sqlite finds the file in the web virtual
/// file system: relative to the root, without `.` or `..` segments.
///
/// `x.db`, `./x.db`, `/x.db` and `/dir/../x.db` are all `/x.db`, so the
/// factory opens, deletes and checks one database for all of them (a second
/// spelling opened a second connection on the same file). In memory paths and
/// `file:` uris are unchanged.
String sqfliteFfiWebFixPath(String path) {
  if (isInMemoryDatabasePath(path) || isFileUriDatabasePath(path)) {
    return path;
  }
  return p.url.normalize(p.url.join('/', path));
}
