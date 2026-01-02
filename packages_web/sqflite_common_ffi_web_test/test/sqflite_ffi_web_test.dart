@TestOn('browser')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web_test/src/import.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

var _factory = createDatabaseFactoryFfiWeb(
  options: SqfliteFfiWebOptions(sharedWorkerUri: Uri.parse('sqflite_sw_v1.js')),
);

class SqfliteFfiWebTestContext extends SqfliteLocalTestContext {
  SqfliteFfiWebTestContext() : super(databaseFactory: _factory);
}

var ffiTestContext = SqfliteFfiWebTestContext();

Future<void> main() async {
  /// Initialize ffi loader
  // sqliteFfiWebDebugWebWorker = true;
  sqfliteFfiInit();
  try {
    var dbsPath = await _factory.getDatabasesPath();
    await _factory.setDatabasesPath('${dbsPath}_web');
    test('options', () async {
      var options = await _factory.getWebOptions();
      expect(options.forceAsBasicWorker, isNull);
      expect(options.sharedWorkerUri, Uri.parse('sqflite_sw_v1.js'));
    });
    all.run(ffiTestContext);
  } catch (e) {
    print('Please run setup_web_tests first');
    test('Please run setup_web_tests first', () {}, skip: true);
  }
}
