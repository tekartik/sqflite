import 'package:sqflite/src/utils.dart';
import 'package:sqflite/src/constant.dart' as constant;

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
/// "hex(blob_field) = ?", Sqlite.hex([1,2,3])
String hex(List<int> bytes) {
  final StringBuffer buffer = StringBuffer();
  for (int part in bytes) {
    if (part & 0xff != part) {
      throw FormatException("$part is not a byte integer");
    }
    buffer.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return buffer.toString().toUpperCase();
}

Duration lockWarningDuration = constant.lockWarningDuration;
void Function() lockWarningCallback = () {
  print('Warning database has been locked for $lockWarningDuration. '
      'Make sure you always use the transaction object for database operations during a transaction');
};

void setLockWarningInfo({Duration duration, void callback()}) {
  lockWarningDuration = duration ?? lockWarningDuration;
  lockWarningCallback = callback ?? lockWarningCallback;
}
