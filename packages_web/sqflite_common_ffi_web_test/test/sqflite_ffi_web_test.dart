@TestOn('browser')
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

var _factory = databaseFactoryFfiWeb;

class SqfliteFfiWebTestContext extends SqfliteLocalTestContext {
  SqfliteFfiWebTestContext() : super(databaseFactory: _factory);
}

var ffiTestContext = SqfliteFfiWebTestContext();

Future<void> main() async {
  /// Initialize ffi loader
  sqfliteFfiInit();
  var dbsPath = await _factory.getDatabasesPath();
  await _factory.setDatabasesPath('${dbsPath}_web');

  all.run(ffiTestContext);
}
