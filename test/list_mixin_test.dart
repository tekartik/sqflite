import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';

class MyList1 extends Object with ListMixin<Map<String, dynamic>> {
  final List _list;

  MyList1.from(this._list);

  @override
  Map<String, dynamic> operator [](int index) {
    Map value = _list[index];
    return value.cast<String, dynamic>();
  }

  @override
  void operator []=(int index, Map<String, dynamic> value) {
    throw "read-only";
  }

  @override
  set length(int newLength) {
    throw "read-only";
  }

  @override
  int get length => _list.length;
}

class MyList2 extends ListBase<Map<String, dynamic>> {
  final List _list;

  MyList2.from(this._list);

  @override
  Map<String, dynamic> operator [](int index) {
    Map value = _list[index];
    return value.cast<String, dynamic>();
  }

  @override
  void operator []=(int index, Map<String, dynamic> value) {
    throw "read-only";
  }

  @override
  set length(int newLength) {
    throw "read-only";
  }

  @override
  int get length => _list.length;
}

main() {
  group("mixin", () {
    // This fails on beta 1, should work now
    test('ListMixin', () {
      var raw = [
        {'col': 1}
      ];
      var rows = new MyList1.from(raw);
      expect(rows, raw);
    });

    test('ListBase', () {
      var raw = [
        {'col': 1}
      ];
      var rows = new MyList2.from(raw);
      expect(rows, raw);
    });
  });
}
