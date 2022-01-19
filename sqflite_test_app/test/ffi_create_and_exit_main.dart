// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  try {
    print('Starting');
    WidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactory.setDatabasesPath(join('.local', 'databases'));
    var db = await databaseFactory.openDatabase('example.db');
    await db.setVersion(1);
    await db.close();
    print('database created');
    exit(0);
  } catch (e) {
    print('error $e');
    exit(1);
  }
}
