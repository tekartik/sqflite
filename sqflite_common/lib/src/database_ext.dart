import 'package:sqflite_common/sqlite_api.dart';

/// Set the journal mode
extension SqfliteDatabaseExt on Database {
  /// On android, the recommended way is to set the journal mode in the
  /// manifest. if not setting the journal mode using execute will fail
  /// so rawQuery should be used instead, so this helper hides the issue.
  ///
  /// This method should be called during onConfigure.
  ///
  /// See
  /// * https://github.com/tekartik/sqflite/issues/929
  /// * https://github.com/tekartik/sqflite/issues/1176
  Future<void> setJournalMode(String journalMode) async {
    try {
      await execute('PRAGMA journal_mode = $journalMode');
    } catch (e) {
      // handle android quirks if wal is not enabled in the manifest.
      await rawQuery('PRAGMA journal_mode = $journalMode');
    }
  }
}
