import 'dart:async';
import 'dart:js_interop';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/import.dart';
import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart'; // ignore: implementation_imports
import 'package:sqflite_common_ffi_web/src/utils.dart';
import 'package:sqflite_common_ffi_web/src/web/js_utils.dart';
import 'package:web/web.dart' as web;

import 'constants.dart';

bool get _debug => sqliteFfiWebDebugWebWorker; // devWarning(true); // false
/// Shared worker globals
var swGlobals = <String, Object?>{};
var _log = print;
SqfliteFfiWebContext? _swContext;
SqfliteFfiWebOptions? _swOptions;

/// Sometimes needed when debugging to ensure we are testing the new version
var _debugVersion = 2;

var _shw = '/shw$_debugVersion';

void _handleMessageEvent(web.Event event) async {
  var messageEvent = event as web.MessageEvent;
  var rawData = messageEvent.data?.dartifyValueStrict();
  var port = messageEvent.ports.toDart.first;
  try {
    if (rawData is String) {
      if (_debug) {
        _log('$_shw receive text message $rawData');
      }
      port.postMessage(rawData.toJS);
    } else {
      if (_debug) {
        _log('$_shw recv $rawData');
      }
      if (rawData is List) {
        var command = rawData[0];

        if (command == commandVarSet) {
          var data = rawData[1] as Map;
          var key = data['key'] as String;
          var value = data['value'] as Object?;
          _log('$_shw $command $key: $value');
          swGlobals[key] = value;
          port.postMessage(null);
        } else if (command == commandVarGet) {
          var data = rawData[1] as Map;
          var key = data['key'] as String;
          var value = swGlobals[key];
          _log('$_shw $command $key: $value');
          port.postMessage({
            'result': {'key': key, 'value': value}
          }.jsifyValueStrict());
        } else {
          _log('$_shw $command unknown');
          port.postMessage(null);
        }
      } else if (rawData is Map) {
        var ffiMethodCall = FfiMethodCall.fromDataMap(rawData);

        if (_debug) {
          _log('$_shw method call $ffiMethodCall');
        }
        if (ffiMethodCall != null) {
          // Fix data
          ffiMethodCall = FfiMethodCall(
              ffiMethodCall.method, dataFromEncodable(ffiMethodCall.arguments));
          // Init context on first call
          if (_swContext == null) {
            if (_debug) {
              _log('$_shw loading wasm');
            }
            _swContext = await sqfliteFfiWebLoadSqlite3Wasm(
                _swOptions ?? SqfliteFfiWebOptions(),
                fromWebWorker: true);
            sqfliteFfiHandler = SqfliteFfiHandlerWeb(_swContext!);
          }
          void postResponse(FfiMethodResponse response) {
            var data = response.toDataMap();
            if (_debug) {
              _log('$_shw resp $data ($port)');
            }
            port.postMessage(data.jsifyValueStrict());
          }

          try {
            var result = await ffiMethodCall.handleImpl();
            result = dataToEncodable(result);
            postResponse(FfiMethodResponse(result: result));
          } catch (e, st) {
            postResponse(FfiMethodResponse.fromException(e, st));
          }
        } else {
          _log('$_shw $rawData unknown');
          port.postMessage(null);
        }
      } else {
        _log('$_shw $rawData map unknown');
        port.postMessage(null);
      }
    }
  } catch (e, st) {
    _log('$_shw error caught $e $st');
    port.postMessage(null);
  }
}

/// Main shared worker entry point. It also works in a simple web worker
void mainSharedWorker(List<String> args) {
  // sqliteFfiWebDebugWebWorker = devWarning(true);
  if (_debug) {
    _log('$_shw main($_debugVersion)');
  }
  var zone = Zone.current;
  try {
    final scope = (globalContext as web.SharedWorkerGlobalScope);
    try {
      var scopeName = scope.name;
      if (_debug) {
        _log('$_shw scopeName: $scopeName');
      }
    } catch (e) {
      if (_debug) {
        _log('$_shw scope.name error $e');
      }
    }

    scope.onconnect = (web.Event event) {
      zone.run(() {
        if (_debug) {
          _log('$_shw onConnect()');
        }
        var connectEvent = event as web.MessageEvent;
        var port = connectEvent.ports.toDart[0];

        port.onmessage = (web.MessageEvent event) {
          zone.run(() {
            _handleMessageEvent(event);
          });
        }.toJS;
      });
    }.toJS;
  } catch (e) {
    if (_debug) {
      _log('$_shw not in shared worker, trying basic worker');
    }
  }

  final scope = (globalContext as web.DedicatedWorkerGlobalScope);
  if (_debug) {
    _log('$_shw basic worker support');
  }

  /// Handle basic web workers
  /// dirty hack
  try {
    scope.onmessage = (web.MessageEvent event) {
      zone.run(() {
        _handleMessageEvent(event);
      });
    }.toJS;
  } catch (e) {
    if (_debug) {
      _log('$_shw not in shared worker error $e');
    }
  }

  if (_debug) {
    _log('$_shw main done ($_debugVersion)');
  }
}
