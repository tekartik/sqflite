import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';

class SqfliteFfiTestContext extends SqfliteLocalTestContext {
  SqfliteFfiTestContext() : super(databaseFactory: databaseFactoryFfi);
}

var ffiTestContext = SqfliteFfiTestContext();

void main() {
  /// Initialize ffi loader
  sqfliteFfiInit();

  group('flutter_ffi', () {
    all.run(ffiTestContext);
  });
}
