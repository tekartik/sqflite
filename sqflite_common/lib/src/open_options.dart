import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/env_utils.dart';

///
/// Options to open a database
/// See [openDatabase] for details
///
class SqfliteOpenDatabaseOptions implements OpenDatabaseOptions {
  /// See [openDatabase] for details
  SqfliteOpenDatabaseOptions({
    this.version,
    this.onConfigure,
    this.onCreate,
    this.onUpgrade,
    this.onDowngrade,
    this.onOpen,
    bool? readOnly = false,
    bool? singleInstance = true,
    bool? rollbackActiveTransactionOnOpen,
  }) : readOnly = readOnly ?? false,
       singleInstance = singleInstance ?? true,
       rollbackActiveTransactionOnOpen =
           rollbackActiveTransactionOnOpen ?? (isDebug);

  @override
  final int? version;
  @override
  final OnDatabaseConfigureFn? onConfigure;
  @override
  final OnDatabaseCreateFn? onCreate;
  @override
  final OnDatabaseVersionChangeFn? onUpgrade;
  @override
  OnDatabaseVersionChangeFn? onDowngrade;
  @override
  final OnDatabaseOpenFn? onOpen;
  @override
  final bool readOnly;
  @override
  final bool singleInstance;

  /// Experimental
  final bool rollbackActiveTransactionOnOpen;

  @override
  String toString() {
    final map = <String, Object?>{};
    if (version != null) {
      map['version'] = version;
    }
    map['readOnly'] = readOnly;
    map['singleInstance'] = singleInstance;
    return map.toString();
  }
}
