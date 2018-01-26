#!/bin/bash

# Fast fail the script on failures.
set -e

# $FLUTTER_ROOT/bin/cache/dart-sdk/bin/dartdoc
flutter analyze lib test
flutter test