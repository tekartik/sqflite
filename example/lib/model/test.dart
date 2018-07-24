import 'dart:async';

class Test {
  final bool solo;
  final bool skip;
  Test(this.name, this.fn, {bool solo, bool skip})
      : solo = solo == true,
        skip = skip == true;
  String name;
  FutureOr Function() fn;
}
