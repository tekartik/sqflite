//import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'constant.dart';
import 'env_utils.dart';
import 'mixin/handler_mixin.dart';

/// An command object representing the invocation of a named method.
@immutable
class FfiMethodCall
//
//    implements
//        MethodCall
//
{
  /// Creates a [MethodCall] representing the invocation of [method] with the
  /// specified [arguments].
  const FfiMethodCall(this.method, [this.arguments]);

  /// The name of the method to be called.
  final String method;

  /// The arguments for the method.
  ///
  /// Must be a valid value for the [MethodCodec] used.
  final Object? arguments;

  @override
  String toString() => '$runtimeType($method, $arguments)';

  /// Data map for invocation.
  Map<String, Object?> toDataMap() {
    var map = <String, Object?>{
      'method': method,
      'arguments': arguments,
    };
    return map;
  }

  /// Ffi method call from a data map. (isolate, web worker receivers)
  static FfiMethodCall? fromDataMap(Map map) {
    var method = map['method'];
    var arguments = map['arguments'];
    if (method != null) {
      return FfiMethodCall(method as String, arguments);
    }
    return null;
  }
}

/// Ffi method response.
///
/// TODO make it to sqflite_common to be reused in sqflite
class FfiMethodResponse {
  /// The result dartified.
  late final Object? result;

  /// The result mappified.
  late final Object? error;

  /// Ffi method response.
  FfiMethodResponse({this.result, this.error});

  /// Response from an exception
  FfiMethodResponse.fromException(Object? e, [StackTrace? st]) {
    var error = <String, Object?>{};
    if (e is SqfliteFfiException) {
      error['code'] = e.code;
      error['details'] = e.details;
      error['message'] = e.message;
      error['resultCode'] = e.getResultCode();
      error['transactionClosed'] = e.transactionClosed;
    } else {
      // should not happen
      error['message'] = e.toString();
    }
    if (isDebug && st != null) {
      error['stackTrace'] = st.toString();
    }
    this.error = error;
    result = null;
  }

  /// Data map for invocation.
  Map<String, Object?> toDataMap() {
    var map = <String, Object?>{
      if (result != null)
        'result': result
      else if (error != null)
        'error': error,
    };
    return map;
  }

  /// Ffi method call from a data map. (isolate, web worker receivers)
  static FfiMethodResponse? fromDataMap(Map map) {
    var result = map['result'];
    var error = map['error'];
    return FfiMethodResponse(result: result, error: error);
  }

  /// Exception from a response
  SqfliteFfiException toException() {
    var errorMap = error;
    if (errorMap is Map) {
      return SqfliteFfiException(
          code: (errorMap['code'] as String?) ?? anyErrorCode,
          message: errorMap['message'] as String,
          details: (errorMap['details'] as Map?)?.cast<String, Object?>(),
          resultCode: errorMap['resultCode'] as int?,
          transactionClosed: errorMap['transactionClosed'] as bool?);
    } else {
      return SqfliteFfiException(
          code: anyErrorCode, message: error?.toString() ?? 'no info');
    }
  }
}

/// Either return a result of throw an exception
Object? responseToResultOrThrow(Object? response) {
  if (response is Map) {
    var ffiResponse = FfiMethodResponse.fromDataMap(response);
    if (ffiResponse != null) {
      if (ffiResponse.error != null) {
        throw ffiResponse.toException();
      }
      return ffiResponse.result;
    }
  }
  return response;
}
