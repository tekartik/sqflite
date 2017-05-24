import 'dart:async';
import 'package:func/func.dart';
import 'package:matcher/matcher.dart';

/*
void expect(dynamic actual, Matcher matcher, {
  String reason,
}) {
  if (matcher.matches(item, matchState))
  test_package.expect(actual, matcher, reason: reason);
}
*/

class Test {
  Test(this.name, this.fn);
  String name;
  Func0<FutureOr> fn;

}