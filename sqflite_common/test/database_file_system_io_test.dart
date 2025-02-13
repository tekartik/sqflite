import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite_common/src/database_file_system_io.dart';
import 'package:test/test.dart';

void main() {
  var fileSystem = DatabaseFileSystemIo();
  group('database_file_sytem_io', () {
    test('read/write', () async {
      var path = join(
        '.dart_tool',
        'sqflite_common',
        'database_file_sytem_io',
        'test.db',
      );
      await fileSystem.deleteDatabase(path);
      try {
        await fileSystem.readDatabaseBytes(path);
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
      await fileSystem.writeDatabaseBytes(path, Uint8List.fromList([1, 2, 3]));
      expect(await fileSystem.readDatabaseBytes(path), [1, 2, 3]);
    });
  });
}
