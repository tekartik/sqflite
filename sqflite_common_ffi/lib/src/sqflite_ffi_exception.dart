import 'package:meta/meta.dart';
import 'package:sqflite_common_ffi/src/sqflite_ffi_impl.dart';
import 'package:sqflite_common_ffi/src/sqflite_import.dart';

/// Ffi exception.
class SqfliteFfiException extends SqfliteDatabaseException {
  /// Ffi exception.
  SqfliteFfiException(
      {@required this.code,
      @required String message,
      this.details,
      int resultCode})
      : super(message, details, resultCode: resultCode);

  /// The database.
  SqfliteFfiDatabase database;

  /// SQL statement.
  String sql;

  /// SQL arguments.
  List<dynamic> sqlArguments;

  /// Error code.
  final String code;

  /// Error details.
  Map<String, dynamic> details;

  int get _resultCode => getResultCode();

  @override
  String toString() {
    var map = <String, dynamic>{};
    if (details != null) {
      map['details'] = details;
    }
    return 'SqfliteFfiException($code${_resultCode == null ? '' : ': $_resultCode, '}, $message} ${super.toString()} $map';
  }
}
