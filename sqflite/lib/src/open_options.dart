import 'package:sqflite/sqlite_api.dart';

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
    this.readOnly = false,
    this.singleInstance = true,
    this.extraOptions,
  }) {
    readOnly ??= false;
    singleInstance ??= true;
  }
  @override
  int version;
  @override
  OnDatabaseConfigureFn onConfigure;
  @override
  OnDatabaseCreateFn onCreate;
  @override
  OnDatabaseVersionChangeFn onUpgrade;
  @override
  OnDatabaseVersionChangeFn onDowngrade;
  @override
  OnDatabaseOpenFn onOpen;
  @override
  bool readOnly;
  @override
  bool singleInstance;
  @override
  Map<String, dynamic> extraOptions;

  @override
  String toString() {
    final map = <String, dynamic>{};
    if (version != null) {
      map['version'] = version;
    }
    map['readOnly'] = readOnly;
    map['singleInstance'] = singleInstance;
    if (map != null) {
      map.addAll(extraOptions);
    }
    return map.toString();
  }
}
