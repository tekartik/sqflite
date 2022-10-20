import 'dart:html';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/import.dart';
import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart'; // ignore: implementation_imports
import 'package:sqflite_common_ffi_web/src/utils.dart';

import 'constants.dart';

bool get _debug => sqliteFfiWebDebugWebWorker; // devWarning(true); // false
/// Shared worker globals
var swGlobals = <String, Object?>{};

SqfliteFfiWebContext? _swContext;
SqfliteFfiWebOptions? _swOptions;

/// Sometimes needed when debugging to ensure we are testing the new version
var _debugVersion = 2;

var _shw = '/shw$_debugVersion';

Future<void> _handleMessageEvent(Event event) async {
  var messageEvent = event as MessageEvent;
  var rawData = messageEvent.data;
  var port = messageEvent.ports.first;
  try {
    if (rawData is String) {
      if (_debug) {
        print('$_shw receive text message $rawData');
      }
      port.postMessage(rawData);
    } else {
      if (_debug) {
        print('$_shw recv $rawData');
      }
      if (rawData is List) {
        var command = rawData[0];

        if (command == commandVarSet) {
          var data = rawData[1] as Map;
          var key = data['key'] as String;
          var value = data['value'] as Object?;
          print('$_shw $command $key: $value');
          swGlobals[key] = value;
          port.postMessage(null);
        } else if (command == commandVarGet) {
          var data = rawData[1] as Map;
          var key = data['key'] as String;
          var value = swGlobals[key];
          print('$_shw $command $key: $value');
          port.postMessage({
            'result': {'key': key, 'value': value}
          });
        } else {
          print('$_shw $command unknown');
          port.postMessage(null);
        }
      } else if (rawData is Map) {
        var ffiMethodCall = FfiMethodCall.fromDataMap(rawData);

        if (_debug) {
          print('$_shw method call $ffiMethodCall');
        }
        if (ffiMethodCall != null) {
          // Fix data
          ffiMethodCall = FfiMethodCall(
              ffiMethodCall.method, dataFromEncodable(ffiMethodCall.arguments));
          // Init context on first call
          if (_swContext == null) {
            if (_debug) {
              print('$_shw loading wasm');
            }
            _swContext = await sqfliteFfiWebLoadSqlite3Wasm(
                _swOptions ?? SqfliteFfiWebOptions(),
                fromWebWorker: true);
            sqfliteFfiHandler = SqfliteFfiHandlerWeb(_swContext!);
          }
          void postResponse(FfiMethodResponse response) {
            port.postMessage(response.toDataMap());
          }

          try {
            var result = await ffiMethodCall.handleImpl();
            result = dataToEncodable(result);
            postResponse(FfiMethodResponse(result: result));
          } catch (e, st) {
            postResponse(FfiMethodResponse.fromException(e, st));
          }
        } else {
          print('$_shw $rawData unknown');
          port.postMessage(null);
        }
      } else {
        print('$_shw $rawData map unknown');
        port.postMessage(null);
      }
    }
  } catch (e, st) {
    print('$_shw error caught $e $st');
    port.postMessage(null);
  }
}

/// Main shared worker entry point. It also works in a simple web worker
void mainSharedWorker(List<String> args) {
  // sqliteFfiWebDebugWebWorker = devWarning(true);
  if (_debug) {
    print('$_shw main($_debugVersion)');
  }

  try {
    SharedWorkerGlobalScope.instance.onConnect.listen((event) async {
      if (_debug) {
        print('$_shw onConnect()');
      }
      var port = (event as MessageEvent).ports.first;
      port.addEventListener('message', _handleMessageEvent);
    });
  } catch (e) {
    if (_debug) {
      print('$_shw not in shared worker, trying basic worker');
    }

    try {
      WorkerGlobalScope.instance
          .addEventListener('message', _handleMessageEvent);
    } catch (e) {
      if (_debug) {
        print('$_shw not in shared worker');
      }
    }
  }
  if (_debug) {
    print('$_shw main done ($_debugVersion)');
  }
}
