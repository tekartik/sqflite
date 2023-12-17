import 'package:sqflite_common_ffi_async/src/import.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite_async;

/// Write transaction.
class SqfliteFfiAsyncTransaction extends SqfliteTransaction {
  /// Write context.
  final sqlite_async.SqliteWriteContext writeContext;

  /// Write transaction.
  SqfliteFfiAsyncTransaction(super.database, this.writeContext);
}

/// Read transaction.
class SqfliteFfiAsyncReadTransaction extends SqfliteTransaction {
  /// Read context.
  final sqlite_async.SqliteReadContext readContext;

  /// Read transaction.
  SqfliteFfiAsyncReadTransaction(super.database, this.readContext);
}
