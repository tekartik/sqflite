# sqflite_example

Demonstrates how to use the [sqflite plugin](https://github.com/tekartik/sqflite).

## Getting Started

dependencies:

```yaml
  sqflite_example_common:
    git:
      url: https://github.com/tekartik/sqflite
      path: packages_flutter/sqflite_example_common
```

## Running the example

### Linux

```bash
flutter create -p linux
flutter run -d linux --target=lib/main_ffi.dart
```