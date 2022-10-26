// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_test_app/setup_flutter.dart';

class SqfliteDriverTestContext extends SqfliteLocalTestContext {
  SqfliteDriverTestContext() : super(databaseFactory: databaseFactory);

  @override
  bool get supportsRecoveredInTransaction => true;
}

var testContext = SqfliteDriverTestContext();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    sqfliteFfiInitAsMockMethodCallHandler();
  }

  group('integration', () {
    all.run(testContext);
  });
}
