@TestOn('vm')
library;

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:test/test.dart';

void main() {
  test('web only factories', () {
    Matcher webOnly(String name) => throwsA(
      isA<UnsupportedError>()
          .having((e) => e.message, 'message', contains(name))
          .having(
            (e) => e.message,
            'message',
            contains('only supported on the web'),
          ),
    );
    expect(() => databaseFactoryFfiWeb, webOnly('databaseFactoryFfiWeb is'));
    expect(
      () => databaseFactoryFfiWebNoWebWorker,
      webOnly('databaseFactoryFfiWebNoWebWorker'),
    );
    expect(
      () => databaseFactoryFfiWebBasicWebWorker,
      webOnly('databaseFactoryFfiWebBasicWebWorker'),
    );
    expect(createDatabaseFactoryFfiWeb, webOnly('createDatabaseFactoryFfiWeb'));
  });
}
