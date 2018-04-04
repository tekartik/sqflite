#!/bin/bash

# Fast fail the script on failures.
set -e

flutter analyze lib test
flutter analyze --preview-dart-2 lib test

flutter test
flutter test --preview-dart-2

# example
pushd example

flutter analyze lib test
flutter analyze --preview-dart-2 lib test

flutter test
flutter test --preview-dart-2

# dartdoc