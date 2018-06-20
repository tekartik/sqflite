#!/usr/bin/env bash

# Fast fail the script on failures.
# and print line as they are read
set -ev

flutter --version

flutter packages get

flutter analyze --no-current-package lib test
# flutter analyze --no-current-package --preview-dart-2 lib test

flutter test
# flutter test --preview-dart-2

# example
pushd example

flutter packages get

flutter analyze --no-current-package lib test
# flutter analyze --no-current-package --preview-dart-2 lib test

flutter test
# flutter test --preview-dart-2

# dartdoc