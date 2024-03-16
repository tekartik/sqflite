@TestOn('browser')
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

var _factory = databaseFactoryFfiWebNoWebWorker;

class SqfliteFfiWebNoWebWorkerTestContext extends SqfliteLocalTestContext {
  SqfliteFfiWebNoWebWorkerTestContext() : super(databaseFactory: _factory);
}

var ffiTestContext = SqfliteFfiWebNoWebWorkerTestContext();

Future<void> main() async {
  /// Tmp debug
  // sqliteFfiWebDebugWebWorker = true;

  /// Initialize ffi loader
  //sqfliteFfiInit();
  // Add _no_isolate suffix to the path
  try {
    var dbsPath = await _factory.getDatabasesPath();
    await _factory.setDatabasesPath('${dbsPath}_no_web_worker');

    all.run(ffiTestContext);
  } catch (e) {
    print('Please run setup_web_tests first');
    test('Please run setup_web_tests first', () {}, skip: true);
  }
}
