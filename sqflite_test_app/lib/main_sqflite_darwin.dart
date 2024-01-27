import 'package:flutter/cupertino.dart';
import 'package:sqflite_darwin/sqflite_darwin.dart';
import 'package:sqflite_example/main.dart';

/// Use regular sqflite, overridng to use Darwin iOS and MacOS
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initSqfliteDarwinPlugin();
  mainExampleApp();
}
