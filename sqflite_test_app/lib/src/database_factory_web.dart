import 'package:sqflite_common/sqlite_api.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/method_call.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/mixin/import_mixin.dart';

// ignore_for_file: avoid_print

DatabaseFactory? _databaseFactoryWebImpl;

/// The Ffi database factory.
DatabaseFactory get databaseFactoryWeb =>
    _databaseFactoryWebImpl ??= buildDatabaseFactory(
        tag: 'web',
        invokeMethod: (String method, [dynamic arguments]) {
          final methodCall = SqfliteMethodCall(method, arguments);
          return methodCall.handle();
        });

bool _debug = true;

/// Extension on MethodCall
extension WebMethodCallHandler on SqfliteMethodCall {
  /// Handle a method call
  Future<dynamic> handle() async {
    try {
      if (_debug) {
        print('main_send: $this');
      }
      const result = 'TODO';

      ///
      /// TODO Implement Web support
      ///
      if (_debug) {
        print('main_recv: $result');
      }
      return result;
    } catch (e, st) {
      if (_debug) {
        print(e);
        print(st);
      }
      rethrow;
    }
  }
}
