import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Get object keys
@JS('Object.keys')
external JSArray jsObjectKeys(JSObject object);

/// See https://github.com/dart-lang/sdk/issues/55203#issuecomment-2003246663
num wasmDartifyNum(JSNumber value) {
  final jsDouble = value.toDartDouble;
  final jsInt = jsDouble.truncate();
  return (jsInt.toDouble() == jsDouble) ? jsInt : jsDouble;
}

/// In JS everything is a double.
num jsDartifyNum(JSNumber value) {
  return value.toDartDouble;
}

/// Special runtime trick to known whether we are in the javascript world
const _isRunningAsJavascript = identical(0, 0.0);

/// JavaScript number extension.
extension SqfliteWebJSNumberExt on JSNumber {
  /// Convert JavaScript number to Dart number
  /// /// See https://github.com/dart-lang/sdk/issues/55203#issuecomment-2003246663
  num get toDartNum =>
      _isRunningAsJavascript ? jsDartifyNum(this) : wasmDartifyNum(this);
}

/// JavaScript Array extension.
extension SqfliteWebJSArrayExt on JSArray {
  /// Get the length of the array missing up to 3.6
  @JS('length')
  external int get compatLength;
}

/// dartify helper for JavaScript objects (handle Uint8List, DateTime, Map, List, String, num, bool)
extension SqfliteWebDartifyExtension on JSAny {
  /// Convert JavaScript object to Dart object
  Object dartifyValueStrict() {
    var value = this;
    if (value.isA<JSString>()) {
      return (value as JSString).toDart;
    } else if (value.isA<JSNumber>()) {
      return (value as JSNumber).toDartNum;
    } else if (value.isA<JSBoolean>()) {
      return (value as JSBoolean).toDart;
    } else if (value.isA<JSUint8Array>()) {
      return (value as JSUint8Array).toDart;
    } else if (value.isA<JSArray>()) {
      var jsArray = value as JSArray;
      var list = List.generate(
        jsArray.compatLength,
        (index) => jsArray.getProperty(index.toJS)?.dartifyValueStrict(),
      );
      return list;
    }
    try {
      var jsObject = value as JSObject;
      var object = <String, Object?>{};
      var keys = jsObjectKeys(jsObject).toDart;
      for (var key in keys) {
        object[(key as JSString).toDart] = jsObject
            .getProperty(key)
            ?.dartifyValueStrict();
      }
      return object;
    } catch (e) {
      throw UnsupportedError(
        'Unsupported value: $value (type: ${value.runtimeType}) ($e)',
      );
    }
  }
}

/// jsify helper for Dart objects (handle Uint8List, DateTime, Map, List, String, num, bool)
extension SqfliteWebJsifyExtension on Object {
  /// Convert Dart object to JavaScript object
  JSAny jsifyValueStrict() {
    var value = this;
    if (value is String) {
      return value.toJS;
    } else if (value is num) {
      return value.toJS;
    } else if (value is Map) {
      var jsObject = JSObject();
      value.forEach((key, value) {
        jsObject[(key as String)] = (value as Object?)?.jsifyValueStrict();
      });
      return jsObject;
    } else if (value is List) {
      if (value is Uint8List) {
        return value.toJS; // value.buffer.toJS;
      }
      var jsArray = JSArray.withLength(value.length);
      for (var (i, item) in value.indexed) {
        jsArray.setProperty(i.toJS, (item as Object?)?.jsifyValueStrict());
      }
      return jsArray;
    } else if (value is bool) {
      return value.toJS;
    }
    throw UnsupportedError(
      'Unsupported value: $value (type: ${value.runtimeType})',
    );
  }
}
