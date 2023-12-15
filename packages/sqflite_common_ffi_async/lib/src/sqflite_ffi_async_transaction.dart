import 'package:sqflite_common_ffi_async/src/import.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite_async;

class SqfliteFfiAsyncTransaction extends SqfliteTransaction {
  final sqlite_async.SqliteWriteContext writeContext;
  SqfliteFfiAsyncTransaction(super.database, this.writeContext);
}
