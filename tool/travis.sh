#!/bin/bash

# Fast fail the script on failures.
set -e

flutter analyze lib test
flutter test
dartdoc