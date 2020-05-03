import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  test('Sqflite driver test', () async {
    final driver = await FlutterDriver.connect();
    await driver.requestData(null, timeout: const Duration(minutes: 3));
    await driver.close();
  });
}
