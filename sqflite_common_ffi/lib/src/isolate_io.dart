import 'dart:async';
import 'dart:isolate';

import 'package:sqflite_common/src/mixin/constant.dart'; // ignore: implementation_imports
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/method_call.dart';

import 'sqflite_ffi_impl.dart';

bool _debug = false; // devWarning(true); // false;

/// Default timeout when checking that an existing isolate is alive.
const sqfliteIsolatePingDefaultTimeout = Duration(seconds: 2);

/// Interface to share the sqflite isolate send port between isolates.
///
/// Typically implemented using Flutter `IsolateNameServer` (see the
/// `sqflite_ffi` package) so that a single sqflite isolate is shared
/// by all the isolates of an application.
abstract class SqfliteFfiIsolatePortServer {
  /// Looks up a previously registered sqflite isolate send port.
  ///
  /// Returns null if no port is registered.
  SendPort? lookupPort();

  /// Registers the sqflite isolate send port.
  ///
  /// Returns true if the registration succeeded, false if a port was
  /// already registered (for example by another isolate).
  bool registerPort(SendPort sendPort);

  /// Removes the sqflite isolate send port registration.
  ///
  /// Returns true if a registration was removed.
  bool unregisterPort();
}

/// Sqflite isolate.
class SqfliteIsolate {
  /// Sqflite isolate.
  SqfliteIsolate({required this.sendPort});

  /// Our send port.
  final SendPort sendPort;

  /// Checks that the isolate behind [sendPort] is alive and responding.
  ///
  /// Mainly needed when the port comes from a [SqfliteFfiIsolatePortServer]
  /// since a registration could refer to a dead isolate (for example after
  /// a hot restart).
  Future<bool> ping({
    Duration timeout = sqfliteIsolatePingDefaultTimeout,
  }) async {
    var recvPort = ReceivePort();
    try {
      var map = const FfiMethodCall(methodGetDatabasesPath).toDataMap();
      map['sendPort'] = recvPort.sendPort;
      sendPort.send(map);
      await recvPort.first.timeout(timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      recvPort.close();
    }
  }

  /// Handle a method call.
  Future<dynamic> handle(FfiMethodCall methodCall) async {
    var recvPort = ReceivePort();
    var map = methodCall.toDataMap();
    if (_debug) {
      // ignore: avoid_print
      print('send $map');
    }
    map['sendPort'] = recvPort.sendPort;

    sendPort.send(map);
    var response = await recvPort.first;
    if (_debug) {
      // ignore: avoid_print
      print('recv $response');
    }
    return responseToResultOrThrow(response);
  }
}

/// Create an isolate.
///
/// If a [portServer] is provided (typically based on Flutter
/// `IsolateNameServer`), an existing sqflite isolate is reused if one is
/// registered and alive, otherwise a new isolate is spawned and registered.
Future<SqfliteIsolate> createIsolate(
  SqfliteFfiInit? ffiInit, {
  SqfliteFfiIsolatePortServer? portServer,
}) async {
  if (portServer != null) {
    var existingIsolate = await _lookupIsolate(portServer);
    if (existingIsolate != null) {
      return existingIsolate;
    }
  }

  // create a long-lived port for receiving messages
  var ourFirstReceivePort = ReceivePort();

  // spawn the isolate with an initial sendPort.
  var spawnedIsolate = await Isolate.spawn(_isolate, [
    ourFirstReceivePort.sendPort,
    ffiInit,
  ], debugName: "SqfliteIsolate");

  // the isolate sends us its SendPort as its first message.
  // this lets us communicate with it. we’ll always use this port to
  // send it messages.
  var sendPort = (await ourFirstReceivePort.first) as SendPort;

  if (portServer != null && !portServer.registerPort(sendPort)) {
    // Another isolate registered its port first, use it if alive.
    var existingIsolate = await _lookupIsolate(portServer);
    if (existingIsolate != null) {
      // Nobody else knows about our spawned isolate, safe to kill.
      spawnedIsolate.kill();
      return existingIsolate;
    }
    // The registered port was dead and has been unregistered, use ours.
    portServer.registerPort(sendPort);
  }
  return SqfliteIsolate(sendPort: sendPort);
}

/// Returns an isolate from the port server registration, null if none or
/// no longer alive (in which case the registration is removed).
Future<SqfliteIsolate?> _lookupIsolate(
  SqfliteFfiIsolatePortServer portServer,
) async {
  var sendPort = portServer.lookupPort();
  if (sendPort != null) {
    var existingIsolate = SqfliteIsolate(sendPort: sendPort);
    if (await existingIsolate.ping()) {
      return existingIsolate;
    }
    // Dead registration (e.g. leftover from a hot restart), forget it.
    portServer.unregisterPort();
  }
  return null;
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
