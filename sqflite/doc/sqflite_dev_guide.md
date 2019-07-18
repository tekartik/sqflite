# Development guide

## Check list

* run test
* no warning
* string mode / implicit-casts: false
* run `tool/travis.dart`
* run the example

## Publishing

    flutter packages pub publish
    
## Testing

### Using `test_driver`

From the `example` folder, you should be able to run some native tests using:

    flutter driver test_driver/main.dart 