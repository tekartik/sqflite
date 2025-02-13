// ignore: implementation_imports
import 'package:sqflite_platform_interface/src/sqflite_method_channel.dart';

/// Native iOS
const String methodDarwinCreateUnprotectedFolder =
    'darwinCreateUnprotectedFolder';

/// Darwin specific implementation.
class SqfliteDarwin {
  /// Creates an unprotected folder.
  ///
  /// See iOS runtime troubleshooting for more information.
  static Future<void> createUnprotectedFolder(
    String parent,
    String name,
  ) async {
    await invokeMethod<Object?>(
      methodDarwinCreateUnprotectedFolder,
      <String, Object?>{'parent': parent, 'name': name},
    );
  }
}
