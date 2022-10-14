import 'dart:js_util';

import 'package:service_worker/worker.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/import.dart';
import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart'; // ignore: implementation_imports

import 'constants.dart';

var _debug = false; // devWarning(true); // false
/// Service worker globals
var swGlobals = <String, Object?>{};

SqfliteFfiWebContext? _swContext;
SqfliteFfiWebOptions? _swOptions;

/// Main service worker entry point.
void mainServiceWorker(List<String> args) {
  print('/worker main()');
  onInstall.listen((event) {
    print('/worker onInstall()');
  });
  onMessage.listen((ExtendableMessageEvent event) async {
    var port = event.ports!.first;

    try {
      var jsData = event.data;
      if (_debug) {
        print('/worker recv raw $jsData $port');
      }

      if (jsData is String) {
        print('/worker receive text message $jsData');
        port.postMessage(jsData);
      } else {
        var rawData = dartify(jsData);
        if (rawData is List) {
          var command = rawData[0];

          if (command == commandVarSet) {
            var data = rawData[1] as Map;
            var key = data['key'] as String;
            var value = data['value'] as Object?;
            print('/worker $command $key: $value');
            swGlobals[key] = value;
            port.postMessage(null);
          } else if (command == commandVarGet) {
            var data = rawData[1] as Map;
            var key = data['key'] as String;
            var value = swGlobals[key];
            print('/worker $command $key: $value');
            port.postMessage({
              'result': {'key': key, 'value': value}
            });
          } else {
            print('/worker $command unknown');
            port.postMessage(null);
          }
        } else if (rawData is Map) {
          var ffiMethodCall = FfiMethodCall.fromDataMap(rawData);
          if (ffiMethodCall != null) {
            // Init context on first call
            if (_swContext == null) {
              _swContext = await sqfliteFfiWebLoadSqlite3Wasm(
                  _swOptions ?? SqfliteFfiWebOptions(),
                  fromServiceWorker: true);
              sqfliteFfiHandler = SqfliteFfiHandlerWeb(_swContext!);
            }
            try {
              var result = await ffiMethodCall.handleImpl();
              port.postMessage(FfiMethodResponse(result: result).toDataMap());
            } catch (e, st) {
              port.postMessage(FfiMethodResponse.fromException(e, st));
            }
          } else {
            print('/worker $rawData unknown');
            port.postMessage(null);
          }
        } else {
          print('/worker $rawData map unknown');
          port.postMessage(null);
        }
      }
    } catch (e, st) {
      print('/worker error caught $e $st');
      port.postMessage(null);
    }
  });
}
