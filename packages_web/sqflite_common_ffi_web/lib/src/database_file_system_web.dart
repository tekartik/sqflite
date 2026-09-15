import 'dart:typed_data';

// ignore: implementation_imports
import 'package:sqflite_common/src/mixin/platform.dart';
import 'package:sqlite3/wasm.dart';

/// Database file system on sqlite virtual file system.
class SqfliteDatabaseFileSystemFfiWeb implements DatabaseFileSystem {
  /// Database file system on sqlite virtual file system.
  SqfliteDatabaseFileSystemFfiWeb(this.fs);

  ///  sqlite virtual file system.
  final VirtualFileSystem fs;

  /// Resolve the path the way sqlite does when opening a database.
  ///
  /// sqlite calls [VirtualFileSystem.xFullPathName] on the database name
  /// before opening the file, so the same conversion is needed to find the
  /// file again (for example `/dir/../test.db` or an absolute url such as
  /// `http://localhost/test.db` both resolve to `/test.db`).
  String _fullPath(String path) => fs.xFullPathName(path);

  @override
  Future<bool> databaseExists(String path) async {
    // Ignore failure
    try {
      return fs.xAccess(_fullPath(path), 0) != 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> deleteDatabase(String path) async {
    var fullPath = _fullPath(path);
    // Must test, otherwise xDelete throws
    var exists = fs.xAccess(fullPath, 0) != 0;
    if (exists) {
      fs.xDelete(fullPath, 0);
      await _flush();
    }
  }

  @override
  Future<Uint8List> readDatabaseBytes(String path) async {
    await _flush();
    final file = fs
        .xOpen(Sqlite3Filename(_fullPath(path)), SqlFlag.SQLITE_OPEN_READONLY)
        .file;
    try {
      var size = file.xFileSize();
      var target = Uint8List(size);
      file.xRead(target, 0);
      return target;
    } finally {
      file.xClose();
    }
  }

  Future<void> _flush() async {
    var fs = this.fs;

    if (fs is IndexedDbFileSystem) {
      try {
        await fs.flush();
      } catch (_) {}
    }
  }

  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) async {
    await _flush();
    final file = fs
        .xOpen(
          Sqlite3Filename(_fullPath(path)),
          SqlFlag.SQLITE_OPEN_READWRITE | SqlFlag.SQLITE_OPEN_CREATE,
        )
        .file;
    try {
      file.xTruncate(0);
      file.xWrite(bytes, 0);

      await _flush();
    } finally {
      file.xClose();
    }
  }
}
