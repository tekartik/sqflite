#!/bin/bash

# Fast fail the script on failures.
set -e

# not working currently
# $FLUTTER_ROOT/bin/cache/dart-sdk/bin/dartdoc
flutter analyze lib test
flutter test

pushd example
flutter analyze lib test
flutter test