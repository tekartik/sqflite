# Unit test

Currently testing using the package `test` or `flutter_test` is not supported. Testing using sqflite requires running
on a real supported platforms. That's unfortunately an issue for all plugins where mocking cannot easily be done.

Possible alternative (not as good though) are:

## Using flutter_driver

A solution is to use flutter driver. Look at the example app:

```bash
flutter driver --target=test_driver/main.dart
```

## Running as a regular application

Another option is to run the tests as a regular flutter application

```bash
flutter run test/my_sqflite_test.dart
```

## More...

Unfortunately none of the alternatives reports error in a consistent way without looking at the logs.

### Sqflite server

Some experiments are done using a [sqflite server](https://github.com/tekartik/sqflite_more/tree/master/sqflite_test)

### E2E

That seems to be the future solution for testing plugins and native code.
The example app also has a simple (and incomplete) e2e testing (could not really find a difference with flutter driver so far and the doc is not complete to allow iOS/Android and MacOS testing).
