# sqflite_example

Demonstrates how to use the [sqflite plugin](https://github.com/tekartik/sqflite).

## Quick test

    flutter run
    
Specific app entry point
    
    flutter run -t lib/main.dart

## Android

Some project files is no longer in source control but can be re-created using

    flutter create --platforms android .

### Tests

    cd android

    # Java unit test
    ./gradlew test

    # With a emulator running
    ./gradlew connectedAndroidTest

## Getting Started

For help getting started with Flutter, view the online
[documentation](https://flutter.io/).
