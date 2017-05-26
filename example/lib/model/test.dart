import 'dart:async';
import 'package:func/func.dart';

class Test {
  Test(this.name, this.fn);
  String name;
  Func0<FutureOr> fn;
}
