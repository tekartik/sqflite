import 'package:sqflite/src/utils.dart';
import 'package:sqflite/src/utils.dart' as impl;

/// helper to get the first int value in a query
/// Useful for COUNT(*) queries
int firstIntValue(List<Map<String, dynamic>> list) {
  if (list != null && list.isNotEmpty) {
    final Map<String, dynamic> firstRow = list.first;
    if (firstRow.isNotEmpty) {
      return parseInt(firstRow.values?.first);
    }
  }
  return null;
}

/// Utility to encode a blob to allow blow query using
/// 'hex(blob_field) = ?', Sqlite.hex([1,2,3])
String hex(List<int> bytes) {
  final StringBuffer buffer = StringBuffer();
  for (int part in bytes) {
    if (part & 0xff != part) {
      throw FormatException('$part is not a byte integer');
    }
    buffer.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return buffer.toString().toUpperCase();
}

/// Deprecated since 1.1.7+.
///
/// Used internally.
@deprecated
void Function() get lockWarningCallback => impl.lockWarningCallback;

/// Deprecated since 1.1.7+.
@deprecated
set lockWarningCallback(void Function() callback) =>
    impl.lockWarningCallback = callback;

/// Deprecated since 1.1.7+.
@deprecated
Duration get lockWarningDuration => impl.lockWarningDuration;

/// Deprecated since 1.1.7+.
@deprecated
set lockWarningDuration(Duration duration) =>
    impl.lockWarningDuration = duration;

/// Change database lock behavior mechanism.
///
/// Default behavior is to print a message if a command hangs for more than
/// 10 seconds. Set en empty callback (not null) to prevent it from being
/// displayed.
void setLockWarningInfo({Duration duration, void Function() callback}) {
  impl.lockWarningDuration = duration ?? impl.lockWarningDuration;
  impl.lockWarningCallback = callback ?? impl.lockWarningCallback;
}
