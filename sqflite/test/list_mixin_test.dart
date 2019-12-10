import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';

class MyList1 extends Object with ListMixin<Map<String, dynamic>> {
  MyList1.from(this._list);

  final List<dynamic> _list;

  @override
  Map<String, dynamic> operator [](int index) {
    final Map<dynamic, dynamic> value = _list[index] as Map<dynamic, dynamic>;
    return value.cast<String, dynamic>();
  }

  @override
  void operator []=(int index, Map<String, dynamic> value) {
    throw 'read-only';
  }

  @override
  set length(int newLength) {
    throw 'read-only';
  }

  @override
  int get length => _list.length;
}

class MyList2 extends ListBase<Map<String, dynamic>> {
  MyList2.from(this._list);

  final List<dynamic> _list;

  @override
  Map<String, dynamic> operator [](int index) {
    final Map<dynamic, dynamic> value = _list[index] as Map<dynamic, dynamic>;
    return value.cast<String, dynamic>();
  }

  @override
  void operator []=(int index, Map<String, dynamic> value) {
    throw 'read-only';
  }

  @override
  set length(int newLength) {
    throw 'read-only';
  }

  @override
  int get length => _list.length;
}

void main() {
  group('mixin', () {
    // This fails on beta 1, should work now
    test('ListMixin', () {
      final List<dynamic> raw = <dynamic>[
        <dynamic, dynamic>{'col': 1}
      ];
      final MyList1 rows = MyList1.from(raw);
      expect(rows, raw);
    });

    test('ListBase', () {
      final List<dynamic> raw = <dynamic>[
        <dynamic, dynamic>{'col': 1}
      ];
      final MyList2 rows = MyList2.from(raw);
      expect(rows, raw);
    });
  });
}
