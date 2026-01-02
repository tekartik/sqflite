import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_test/sqflite_test.dart';

class SqfliteFfiWebNoWebWorkerTestContext extends SqfliteLocalTestContext {
  SqfliteFfiWebNoWebWorkerTestContext()
    : super(databaseFactory: databaseFactoryFfiWebNoWebWorker);
}

var ffiWebNoWebWorkerTestContext = SqfliteFfiWebNoWebWorkerTestContext();
