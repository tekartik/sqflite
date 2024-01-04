// ignore: implementation_imports
import 'package:sqflite_common_ffi/src/sqflite_ffi_impl.dart';
import 'package:sqflite_common_ffi/src/sqflite_import.dart';

/// Ffi exception.
class SqfliteFfiException extends SqfliteDatabaseException {
  /// Ffi exception.
  SqfliteFfiException(
      {required this.code,
      required String message,
      this.details,
      int? resultCode,
      bool? transactionClosed})
      : super(message, details,
            resultCode: resultCode, transactionClosed: transactionClosed);

  /// The database.
  SqfliteFfiDatabase? database;

  /// SQL statement.
  String? sql;

  /// SQL arguments.
  List<Object?>? sqlArguments;

  /// Error code.
  final String code;

  /// Error details.
  Map<String, Object?>? details;

  int? get _resultCode => getResultCode();

  @override
  String toString() {
    var map = <String, Object?>{};
    if (details != null) {
      if (details is Map) {
        var detailsMap =
            Map<String, Object?>.from(details!).cast<String, Object?>();

        /// remove sql and arguments that we h
        detailsMap.remove('arguments');
        detailsMap.remove('sql');
        if (detailsMap.isNotEmpty) {
          map['details'] = detailsMap;
        }
      } else {
        map['details'] = details;
      }
    }
    var sb = StringBuffer();
    sb.write(
        'SqfliteFfiException($code${_resultCode == null ? '' : ': $_resultCode, '}, $message})');
    if (sql != null) {
      sb.write(' sql $sql');
      if (sqlArguments?.isNotEmpty ?? false) {
        sb.write(' args ${argumentsToString(sqlArguments!)}');
      }
    } else {
      sb.write(' ${super.toString()}');
    }
    if (map.isNotEmpty) {
      sb.write(' $map');
    }
    return sb.toString();
  }
}
