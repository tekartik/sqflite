import 'dart:async';
import 'package:func/func.dart';

class Test {
  final bool solo;
  Test(this.name, this.fn, {bool solo}) : solo = solo == true;
  String name;
  Func0<FutureOr> fn;
}
