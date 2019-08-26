int parseInt(Object object) {
  if (object is int) {
    return object;
  } else if (object is String) {
    try {
      return int.parse(object);
    } catch (_) {}
  }
  return null;
}

@deprecated
void devPrint(Object object) {
  print(object);
}

bool debugModeOn = false;

// True if entering, false if leaving, null otherwise
bool getSqlInTransactionArgument(String sql) {
  if (sql != null) {
    final String lowerSql = sql.trim().toLowerCase();

    if (lowerSql.startsWith('begin')) {
      return true;
    } else if (lowerSql.startsWith('commit') ||
        lowerSql.startsWith('rollback')) {
      return false;
    }
  }
  return null;
}
