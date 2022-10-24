import 'dart:async';
import 'dart:isolate';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/method_call.dart';

import 'sqflite_ffi_impl.dart';

bool _debug = false; // devWarning(true); // false;

/// Sqflite isolate.
class SqfliteIsolate {
  /// Sqflite isolate.
  SqfliteIsolate({required this.sendPort});

  /// Our send port.
  final SendPort sendPort;

  /// Handle a method call.
  Future<dynamic> handle(FfiMethodCall methodCall) async {
    var recvPort = ReceivePort();
    var map = methodCall.toDataMap();
    if (_debug) {
      print('send $map');
    }
    map['sendPort'] = recvPort.sendPort;

    sendPort.send(map);
    var response = await recvPort.first;
    if (_debug) {
      print('recv $response');
    }
    return responseToResultOrThrow(response);
  }
}

/// Create an isolate.
Future<SqfliteIsolate> createIsolate(SqfliteFfiInit? ffiInit) async {
  // create a long-lived port for receiving messages
  var ourFirstReceivePort = ReceivePort();

  // spawn the isolate with an initial sendPort.
  await Isolate.spawn(_isolate, [ourFirstReceivePort.sendPort, ffiInit]);

  // the isolate sends us its SendPort as its first message.
  // this lets us communicate with it. we’ll always use this port to
  // send it messages.
  var sendPort = (await ourFirstReceivePort.first) as SendPort;

  return SqfliteIsolate(sendPort: sendPort);
}

/// The isolate
Future _isolate(List<dynamic> args) async {
  // open our receive port. this is like turning on
  // our cellphone.
  var ourReceivePort = ReceivePort();

  final sendPort = args[0] as SendPort;
  final ffiInit = (args[1] as SqfliteFfiInit?);

  // Initialize with the FFI callback if provided
  ffiInit?.call();

  // tell whoever created us what port they can reach us on
  // (like giving them our phone number)
  sendPort.send(ourReceivePort.sendPort);

  // listen for text messages that are sent to us,
  // and respond to them with this algorithm
  await for (var msg in ourReceivePort) {
    // devPrint('msg: $msg');
    // Handle message asynchronously
    unawaited(() async {
      if (msg is Map) {
        var sendPort = msg['sendPort'];

        if (sendPort is SendPort) {
          void sendResponse(FfiMethodResponse response) {
            sendPort.send(response.toDataMap());
          }

          var methodCall = FfiMethodCall.fromDataMap(msg);

          if (methodCall != null) {
            try {
              var result = await methodCall.handleImpl();
              sendResponse(FfiMethodResponse(result: result));
            } catch (e, st) {
              sendResponse(FfiMethodResponse.fromException(e, st));
            }
          }
        }
      }
    }());
  }
}
