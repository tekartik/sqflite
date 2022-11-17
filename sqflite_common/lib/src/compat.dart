import 'factory_mixin.dart';

///
/// internal options.
///
/// Used internally.
///
/// deprecated since 1.1.1
///
@Deprecated('Dev only')
class SqfliteOptions {
  /// deprecated
  SqfliteOptions({this.logLevel});

  // true =<0.7.0
  /// deprecated
  bool? queryAsMapList;

  /// deprecated
  int? androidThreadPriority;

  /// deprecated
  int? androidThreadNumber;

  /// deprecated
  int? logLevel;

  /// deprecated
  Map<String, Object?> toMap() {
    final map = <String, Object?>{};
    if (queryAsMapList != null) {
      map['queryAsMapList'] = queryAsMapList;
    }
    if (androidThreadPriority != null) {
      map['androidThreadPriority'] = androidThreadPriority;
    }
    if (androidThreadNumber != null) {
      map['androidThreadNumber'] = androidThreadNumber;
    }
    if (logLevel != null) {
      map[paramLogLevel] = logLevel;
    }
    return map;
  }

  /// deprecated
  void fromMap(Map<String, Object?> map) {
    final dynamic queryAsMapList = map['queryAsMapList'];
    if (queryAsMapList is bool) {
      this.queryAsMapList = queryAsMapList;
    }
    final dynamic androidThreadPriority = map['androidThreadPriority'];
    if (androidThreadPriority is int) {
      this.androidThreadPriority = androidThreadPriority;
    }
    final dynamic androidThreadNumber = map['androidThreadNumber'];
    if (androidThreadNumber is int) {
      this.androidThreadNumber = androidThreadNumber;
    }
    final dynamic logLevel = map[paramLogLevel];
    if (logLevel is int) {
      this.logLevel = logLevel;
    }
  }
}
