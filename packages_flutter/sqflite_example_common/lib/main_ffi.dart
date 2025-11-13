// ignore: depend_on_referenced_packages
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'main.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  mainExampleApp();
}
