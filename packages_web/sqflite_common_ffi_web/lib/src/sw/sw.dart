import 'dart:js_util';

import 'package:service_worker/worker.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/import.dart';
import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart'; // ignore: implementation_imports
import 'package:sqflite_common_ffi_web/src/utils.dart';

import 'constants.dart';

bool get _debug => sqliteFfiWebDebugWebWorker; // devWarning(true); // false
/// Service worker globals
var swGlobals = <String, Object?>{};

SqfliteFfiWebContext? _swContext;
SqfliteFfiWebOptions? _swOptions;

/// Main service worker entry point.
void mainServiceWorker(List<String> args) {
  // sqliteFfiWebDebugWebWorker = devWarning(true);
  if (_debug) {
    print('/sw_worker main()');
  }
  onInstall.listen((event) {
    if (_debug) {
      print('/sw_worker onInstall()');
    }
  });
  onMessage.listen((ExtendableMessageEvent event) async {
    var port = event.ports!.first;

    try {
      var jsData = event.data;

      if (jsData is String) {
        if (_debug) {
          print('/sw_worker receive text message $jsData');
        }
        port.postMessage(jsData);
      } else {
        var rawData = dartify(jsData);
        if (_debug) {
          print('/sw_worker recv $rawData');
        }
        if (rawData is List) {
          var command = rawData[0];

          if (command == commandVarSet) {
            var data = rawData[1] as Map;
            var key = data['key'] as String;
            var value = data['value'] as Object?;
            print('/sw_worker $command $key: $value');
            swGlobals[key] = value;
            port.postMessage(null);
          } else if (command == commandVarGet) {
            var data = rawData[1] as Map;
            var key = data['key'] as String;
            var value = swGlobals[key];
            print('/sw_worker $command $key: $value');
            port.postMessage({
              'result': {'key': key, 'value': value}
            });
          } else {
            print('/sw_worker $command unknown');
            port.postMessage(null);
          }
        } else if (rawData is Map) {
          var ffiMethodCall = FfiMethodCall.fromDataMap(rawData);

          if (_debug) {
            print('/sw_worker method call $ffiMethodCall');
          }
          if (ffiMethodCall != null) {
            // Fix data
            ffiMethodCall = FfiMethodCall(ffiMethodCall.method,
                dataFromEncodable(ffiMethodCall.arguments));
            // Init context on first call
            if (_swContext == null) {
              if (_debug) {
                print('/sw_worker loading wasm');
              }
              _swContext = await sqfliteFfiWebLoadSqlite3Wasm(
                  _swOptions ?? SqfliteFfiWebOptions(),
                  fromServiceWorker: true);
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
            print('/sw_worker $rawData unknown');
            port.postMessage(null);
          }
        } else {
          print('/sw_worker $rawData map unknown');
          port.postMessage(null);
        }
      }
    } catch (e, st) {
      print('/sw_worker error caught $e $st');
      port.postMessage(null);
    }
  });
}
