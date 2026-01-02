@TestOn('browser')
library;

import 'package:sqflite_common_ffi_web_test/src/common.dart';
import 'package:sqflite_common_ffi_web_test/src/import.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:test/test.dart';

var ffiTestContext = ffiWebNoWebWorkerTestContext;
var _factory = ffiTestContext.databaseFactory;

Future<void> main() async {
  /// Tmp debug
  // sqliteFfiWebDebugWebWorker = true;

  /// Initialize ffi loader
  //sqfliteFfiInit();
  // Add _no_isolate suffix to the path
  try {
    var dbsPath = await _factory.getDatabasesPath();
    await _factory.setDatabasesPath('${dbsPath}_no_web_worker');
    test('options', () async {
      var options = await _factory.getWebOptions();
      expect(options.sharedWorkerUri, isNull);
    });
    all.run(ffiTestContext);
  } catch (e) {
    print('Please run setup_web_tests first');
    test('Please run setup_web_tests first', () {}, skip: true);
  }
}
