//import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

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
  const FfiMethodCall(this.method, [this.arguments]) : assert(method != null);

  /// The name of the method to be called.
  final String method;

  /// The arguments for the method.
  ///
  /// Must be a valid value for the [MethodCodec] used.
  final dynamic arguments;

  @override
  String toString() => '$runtimeType($method, $arguments)';
}
