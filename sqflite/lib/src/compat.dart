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
  int androidThreadPriority;

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (queryAsMapList != null) {
      map['queryAsMapList'] = queryAsMapList;
    }
    if (androidThreadPriority != null) {
      map['androidThreadPriority'] = androidThreadPriority;
    }
    return map;
  }

  void fromMap(Map<String, dynamic> map) {
    final dynamic queryAsMapList = map['queryAsMapList'];
    if (queryAsMapList is bool) {
      this.queryAsMapList = queryAsMapList;
    }
    final dynamic androidThreadPriority = map['androidThreadPriority'];
    if (androidThreadPriority is int) {
      this.androidThreadPriority = androidThreadPriority;
    }
  }
}
