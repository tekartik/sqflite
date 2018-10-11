import 'dart:async';

class Test {
  Test(this.name, this.fn, {bool solo, bool skip})
      : solo = solo == true,
        skip = skip == true;
  final bool solo;
  final bool skip;

  String name;
  FutureOr Function() fn;
}
