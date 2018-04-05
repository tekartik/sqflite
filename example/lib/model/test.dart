import 'dart:async';
import 'package:func/func.dart';

class Test {
  final bool solo;
  final bool skip;
  Test(this.name, this.fn, {bool solo, bool skip})
      : solo = solo == true,
        skip = skip == true;
  String name;
  Func0<FutureOr> fn;
}
