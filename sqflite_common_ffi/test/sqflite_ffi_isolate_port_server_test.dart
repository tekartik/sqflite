@TestOn('vm')
library;

import 'dart:isolate';

import 'package:sqflite_common_ffi/src/isolate.dart';
import 'package:test/test.dart';

/// In memory port server (single isolate, for testing only).
class _TestPortServer implements SqfliteFfiIsolatePortServer {
  SendPort? port;

  @override
  SendPort? lookupPort() => port;

  @override
  bool registerPort(SendPort sendPort) {
    if (port != null) {
      return false;
    }
    port = sendPort;
    return true;
  }

  @override
  bool unregisterPort() {
    if (port == null) {
      return false;
    }
    port = null;
    return true;
  }
}

void main() {
  group('isolate port server', () {
    test('register and reuse', () async {
      var portServer = _TestPortServer();
      expect(portServer.lookupPort(), isNull);

      var isolate = await createIsolate(null, portServer: portServer);
      expect(portServer.lookupPort(), isolate.sendPort);
      expect(await isolate.ping(), isTrue);

      // A second creation should reuse the registered port, not spawn
      // a new isolate.
      var otherIsolate = await createIsolate(null, portServer: portServer);
      expect(otherIsolate.sendPort, isolate.sendPort);
      expect(portServer.lookupPort(), isolate.sendPort);
    });

    test('stale port replaced', () async {
      var portServer = _TestPortServer();

      // Simulate a registration left over by a dead isolate (nobody is
      // listening on this port).
      var deadReceivePort = ReceivePort();
      var deadSendPort = deadReceivePort.sendPort;
      deadReceivePort.close();
      expect(portServer.registerPort(deadSendPort), isTrue);

      var isolate = await createIsolate(null, portServer: portServer);
      expect(isolate.sendPort, isNot(deadSendPort));
      expect(portServer.lookupPort(), isolate.sendPort);
      expect(await isolate.ping(), isTrue);
    });

    test('ping dead port', () async {
      var deadReceivePort = ReceivePort();
      var isolate = SqfliteIsolate(sendPort: deadReceivePort.sendPort);
      deadReceivePort.close();
      expect(
        await isolate.ping(timeout: const Duration(milliseconds: 100)),
        isFalse,
      );
    });
  });
}
