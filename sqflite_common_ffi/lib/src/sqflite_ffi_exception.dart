// ignore: implementation_imports
import 'package:sqflite_common_ffi/src/sqflite_ffi_impl.dart';
import 'package:sqflite_common_ffi/src/sqflite_import.dart';

/// Ffi exception.
class SqfliteFfiException extends SqfliteDatabaseException {
  /// Ffi exception.
  SqfliteFfiException({
    required this.code,
    required String message,
    this.details,
    int? resultCode,
    bool? transactionClosed,
  }) : super(
         message,
         details,
         resultCode: resultCode,
         transactionClosed: transactionClosed,
       );

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

  /// Same format as the native implementations, `DatabaseException` being
  /// the public type to catch:
  /// `DatabaseException(ffi <code> <result code>: <message>) sql '<sql>' args [<args>] {details: ...}`
  @override
  String toString() {
    var detailsMap = details == null
        ? <String, Object?>{}
        : Map<String, Object?>.from(details!);
    // sql and arguments come from the exception (no isolate) or the details
    // (isolate, web worker), shown once.
    var sql = this.sql ?? detailsMap.remove('sql');
    var arguments = sqlArguments ?? detailsMap.remove('arguments');
    detailsMap
      ..remove('sql')
      ..remove('arguments');
    var resultCode = _resultCode;
    var sb = StringBuffer(
      'DatabaseException(ffi $code${resultCode == null ? '' : ' $resultCode'}: $message)',
    );
    if (sql != null) {
      sb.write(" sql '$sql'");
      if (arguments is List && arguments.isNotEmpty) {
        sb.write(' args ${argumentsToString(arguments)}');
      }
    }
    if (detailsMap.isNotEmpty) {
      sb.write(' ${{'details': detailsMap}}');
    }
    return sb.toString();
  }
}
