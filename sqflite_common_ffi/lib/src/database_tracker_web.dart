import 'package:sqlite3/common.dart';

/// Stub database tracker
DatabaseTracker get tracker => _tracker ??= DatabaseTracker();
DatabaseTracker? _tracker;

/// This entire file is an elaborate hack to workaround https://github.com/simolus3/moor/issues/835.
/// Assumption is that this is not required on web.
class DatabaseTracker {
  /// Tracks the [db]. The [path] argument can be used to track the path
  /// of that database, if it's bound to a file.
  void markOpened(CommonDatabase _) {}

  /// Marks the database [db] as closed.
  void markClosed(CommonDatabase _) {}
}
