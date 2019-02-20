///
/// internal options.
///
/// Used internally.
///
/// deprecated since 1.1.1
///
@deprecated
class SqfliteOptions {
  // true =<0.7.0
  bool queryAsMapList;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'queryAsMapList': queryAsMapList};
  }

  void fromMap(Map<String, dynamic> map) {
    final bool queryAsMapList = map['queryAsMapList'] as bool;
    this.queryAsMapList = queryAsMapList;
  }
}
