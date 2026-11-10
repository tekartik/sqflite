// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi_web/src/utils.dart';
import 'package:test/test.dart';

void main() {
  test('dataToEncodable', () {
    expect(dataToEncodable(null), null);
    expect(dataToEncodable({'@': 1}), {
      '@': {'@': 1},
    });
    expect(dataToEncodable(BigInt.one), {'@BigInt': '1'});
    expect(() => dataToEncodable(DateTime.now()), throwsUnsupportedError);
  });
  test('dataFromEncodable', () {
    expect(dataFromEncodable(null), null);
    expect(dataFromEncodable(true), isTrue);
    expect(dataFromEncodable({'@BigInt': '1'}), BigInt.one);
    expect(dataFromEncodable({'@BigInt': null}), isNull);
    expect(dataToEncodable(BigInt.one), {'@BigInt': '1'});
  });
  test(
    'int beyond 2^53 encoded as BigInt',
    () {
      // A JS number (postMessage to the worker) would round it.
      var big = int.parse('9007199254740993');
      expect(dataToEncodable(big), {'@BigInt': '9007199254740993'});
      expect(dataToEncodable(-big), {'@BigInt': '-9007199254740993'});
      expect(dataFromEncodable(dataToEncodable(big)), BigInt.from(big));
      expect(
        dataToEncodable({
          'args': [1, big],
        }),
        {
          'args': [
            1,
            {'@BigInt': '9007199254740993'},
          ],
        },
      );
      // Safe integers are unchanged.
      expect(dataToEncodable(9007199254740991), 9007199254740991);
      expect(dataToEncodable(-9007199254740991), -9007199254740991);
    },
    // dart2js has no 64-bit int (it uses BigInt).
    skip: identical(0.0, 0) ? 'no 64-bit int on dart2js' : false,
  );
  test('toFrom encodable all', () {
    void loop(Object? decoded) {
      var encoded = dataToEncodable(decoded);
      try {
        expect(dataFromEncodable(encoded), decoded);
      } catch (e) {
        print('checking value $decoded $encoded');
        rethrow;
      }
    }

    for (var value in [
      null,
      true,
      1,
      2.0,
      'text',
      {'test': 'value1'},
      ['value1, value2'],
      {'@dummy': '1970-01-01T00:00:01.000000002Z'},
      {
        'nested': [
          BigInt.one,
          [
            {'sub': 1},
            {'subCustom': BigInt.parse('123456789123456789123456789')},
          ],
        ],
      },
    ]) {
      loop(value);
    }
  });
}
