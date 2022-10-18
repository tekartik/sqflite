import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite_dev.dart';

/// Usage: await sleep(500);
Future sleep([int milliseconds = 0]) =>
    Future.delayed(Duration(milliseconds: milliseconds));

/// Only the native plugin supports this
/// could drop support soon
/// 2022-10-18 drop Android support
bool get queryAsMapListSupported {
  // ignore: invalid_use_of_visible_for_testing_member
  return databaseFactory == sqfliteDatabaseFactoryDefault &&
      (!Platform.isAndroid);
}

/// Supports compat mode (devSetDebugModeOn, queryAsMap, fts4, some error handled - missing parameter, bad file)
bool get supportsCompatMode {
  // ignore: invalid_use_of_visible_for_testing_member
  return databaseFactory == sqfliteDatabaseFactoryDefault;
}
