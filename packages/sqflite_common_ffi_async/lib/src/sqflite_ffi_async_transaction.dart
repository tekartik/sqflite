import 'package:sqflite_common_ffi_async/src/import.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite_async;

/// Write transaction.
class SqfliteFfiAsyncTransaction extends SqfliteTransaction {
  /// Write transaction.
  SqfliteFfiAsyncTransaction(super.database, this.writeContext);

  /// Write context.
  final sqlite_async.SqliteWriteContext writeContext;
}

/// Read transaction.
class SqfliteFfiAsyncReadTransaction extends SqfliteTransaction {
  /// Read transaction.
  SqfliteFfiAsyncReadTransaction(super.database, this.readContext);

  /// Read context.
  final sqlite_async.SqliteReadContext readContext;
}
