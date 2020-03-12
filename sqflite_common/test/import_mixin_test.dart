import 'package:sqflite_common/src/mixin/import_mixin.dart';
import 'package:test/test.dart';

void main() {
  group('handler_mixin', () {
    // Check that public api are exported
    test('exported', () {
      <dynamic>[
        // ignore: deprecated_member_use_from_same_package
        SqfliteOptions,
        methodOpenDatabase,
        buildDatabaseFactory, SqfliteInvokeHandler,
        // ignore: deprecated_member_use_from_same_package
        devPrint, devWarning,
        SqfliteDatabaseException,
        methodOpenDatabase, methodOptions, sqliteErrorCode,
      ].forEach((dynamic value) {
        expect(value, isNotNull);
      });
    });
  });
}
