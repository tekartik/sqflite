@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

class SqfliteFfiTestContext extends SqfliteLocalTestContext {
  SqfliteFfiTestContext() : super(databaseFactory: databaseFactoryFfi);
  @override
  bool get supportsUri => true;
}

var ffiTestContext = SqfliteFfiTestContext();

void main() {
  /// Initialize ffi loader
  sqfliteFfiInit();

  all.run(ffiTestContext);
}
