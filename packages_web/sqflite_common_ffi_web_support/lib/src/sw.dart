import 'package:service_worker/worker.dart';
// ignore: implementation_imports
import 'package:sqflite_common_ffi_web/src/web/js_converter.dart';

import 'constants.dart';

/// Service worker globals
var swGlobals = <String, Object?>{};

/// Main service worker entry point.
void mainServiceWorker(List<String> args) {
  print('/worker main()');
  onInstall.listen((event) {
    print('/worker onInstall()');
  });
  onMessage.listen((ExtendableMessageEvent event) {
    var port = event.ports!.first;

    var jsData = event.data;
    if (jsData is String) {
      print('/worker receive text message $jsData');
      port.postMessage(jsData);
    } else {
      var rawData = jsArrayAsList(jsData as List);
      if (rawData != null) {
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
        }
      }
    }
  });
}
