import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/src/open_options_check.dart';
import 'package:test/test.dart';

void main() {
  group('checkOpenDatabaseArgumentsWeb', () {
    test('singleInstance false not supported', () {
      expect(
        () => checkOpenDatabaseArgumentsWeb({
          'path': 'test.db',
          'singleInstance': false,
        }),
        throwsArgumentError,
      );
      expect(
        () => checkOpenDatabaseArgumentsWeb({
          'path': 'test.db',
          'singleInstance': false,
          'readOnly': true,
        }),
        throwsArgumentError,
      );
    });
    test('singleInstance true', () {
      checkOpenDatabaseArgumentsWeb({
        'path': 'test.db',
        'singleInstance': true,
      });
      checkOpenDatabaseArgumentsWeb({'path': 'test.db'});
      checkOpenDatabaseArgumentsWeb(null);
    });
    test('in memory', () {
      checkOpenDatabaseArgumentsWeb({
        'path': inMemoryDatabasePath,
        'singleInstance': false,
      });
      checkOpenDatabaseArgumentsWeb({
        'path': 'file:$inMemoryDatabasePath',
        'singleInstance': false,
      });
    });
  });
}
