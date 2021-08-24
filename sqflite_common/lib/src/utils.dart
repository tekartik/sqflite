import 'constant.dart' as constant;

/// Try to convert anything (int, String) to an int.
int? parseInt(Object? object) {
  if (object is int) {
    return object;
  } else if (object is String) {
    try {
      return int.parse(object);
    } catch (_) {}
  }
  return null;
}

/// Deprecated on purpose to avoid keep in the code.
///
/// Used during development to add a quick log (and to not forget to remove it)
@Deprecated('Dev only')
void devPrint(Object object) {
  print(object);
}

/// Debug mode activated
///
/// To deprecated since 1.1.7
bool debugModeOn = false;

/// True if entering, false if leaving, null otherwise.
bool? getSqlInTransactionArgument(String sql) {
  final lowerSql = sql.trim().toLowerCase();
  if (lowerSql.startsWith('begin')) {
    return true;
  } else if (lowerSql.startsWith('commit') || lowerSql.startsWith('rollback')) {
    return false;
  }
  return null;
}

/// Default duration before printing a lock warning if a database call hangs.
///
/// Non final for changing it during testing.
///
/// If a database called is delayed by this duration, a print will happen.
Duration? lockWarningDuration = constant.lockWarningDurationDefault;

/// Default lock warning callback.
///
/// Use [setLockWarningInfo] instead.
void Function()? lockWarningCallback = _lockWarningCallbackDefault;

void _lockWarningCallbackDefault() {
  print('Warning database has been locked for $lockWarningDuration. '
      'Make sure you always use the transaction object for database operations during a transaction');
}
