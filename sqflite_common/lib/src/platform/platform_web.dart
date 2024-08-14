import 'package:sqflite_common/src/database_file_system.dart';
import 'package:sqflite_common/src/platform/platform.dart';

class _PlatformWeb extends Platform {
  @override
  bool get isWeb => true;

  @override
  DatabaseFileSystem get databaseFileSystem =>
      throw UnimplementedError('$runtimeType.databaseFileSystem');
}

/// Platform (Web)
final platform = _PlatformWeb();
