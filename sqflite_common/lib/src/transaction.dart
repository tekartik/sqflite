import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/batch.dart';
import 'package:sqflite_common/src/constant.dart';
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/database_mixin.dart';

import 'exception.dart';

/// Transaction param, new in transaction v2
class SqfliteTransactionParam {
  /// null for no transaction
  ///
  final int? transactionId;

  /// Transaction param, new in transaction v2.
  SqfliteTransactionParam(this.transactionId);
}

/// Transaction mixin.
mixin SqfliteTransactionMixin implements Transaction {
  /// Optional transaction id, depending on the implementation
  int? transactionId;

  /// True if the transaction has already been terminated (rollback or commit)
  bool? closed;
}

/// Transaction implementation
class SqfliteTransaction
    with SqfliteDatabaseExecutorMixin, SqfliteTransactionMixin
    implements Transaction {
  /// Create a transaction on a given [database]
  SqfliteTransaction(this.database);

  /// The transaction database
  @override
  final SqfliteDatabaseMixin database;

  @override
  SqfliteDatabase get db => database;

  /// True if a transaction is successful
  bool? successful;

  @override
  SqfliteTransaction get txn => this;

  @override
  Batch batch() => SqfliteTransactionBatch(this);
}

/// Special transaction that is run even if a pending transaction is in progress.
SqfliteTransaction getForcedSqfliteTransaction(SqfliteDatabaseMixin database) =>
    SqfliteTransaction(database)..transactionId = paramTransactionIdValueForce;

/// Internal helpers.
extension TransactionPrvExt on Transaction {
  SqfliteTransaction get _txn => this as SqfliteTransaction;

  /// Check if a database is not closed.
  ///
  /// Throw an exception if closed.
  void checkNotClosed() {
    if (_txn.closed == true) {
      throw SqfliteDatabaseException('error transaction_closed', null);
    }
  }

  /// Mark a transaction as closed.
  void markClosed() {
    _txn.closed = true;
  }
}
