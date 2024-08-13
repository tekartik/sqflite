import 'dart:async';
import 'dart:js_interop';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/web/js_utils.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart';
import 'package:web/web.dart' as web;

bool get _debug => sqliteFfiWebDebugWebWorker;

/// Worker client log prefix for debug mode.
var workerClientLogPrefix = '/sw_client'; // Log prefix
var _swc = workerClientLogPrefix; // Log prefix
var _log = print;

/// Genereric Post message handler
abstract class RawMessageSender {
  var _firstMessage = true;

  /// message port parameter
  JSObject messagePortToPortMessageOption(web.MessagePort messagePort) {
    return [messagePort].toJS;
  }

  /// Message to js
  JSAny jsifyMessage(Object message) => message.jsifyValueStrict();

  /// Post message to implement
  void postMessage(Object message, web.MessagePort responsePort);

  /// Returns response
  Future<Object?> sendRawMessage(Object message) {
    var completer = Completer<Object?>();
    // This wraps the message posting/response in a promise, which will resolve if the response doesn't
    // contain an error, and reject with the error if it does. If you'd prefer, it's possible to call
    // controller.postMessage() and set up the onmessage handler independently of a promise, but this is
    // a convenient wrapper.
    var messageChannel = web.MessageChannel();
    //var receivePort =ReceivePort();

    if (_debug) {
      _log('$_swc sending $message');
    }
    final zone = Zone.current;
    messageChannel.port1.onmessage = (web.MessageEvent event) {
      zone.run(() {
        var data = event.data?.dartifyValueStrict();
        if (_debug) {
          _log('$_swc recv $data');
        }
        completer.complete(data);
      });
    }.toJS;

    // Let's handle initialization error on the first message.
    if (_firstMessage) {
      _firstMessage = false;
      onError.listen((event) {
        if (_debug) {
          _log('$_swc error $event');
        }

        if (!completer.isCompleted) {
          completer.completeError(SqfliteFfiWebWorkerException());
        }
      });
    }

    // This sends the message data as well as transferring messageChannel.port2 to the shared worker.
    // The shared worker can then use the transferred port to reply via postMessage(), which
    // will in turn trigger the onmessage handler on messageChannel.port1.
    // See https://html.spec.whatwg.org/multipage/workers.html#dom-worker-postmessage
    postMessage(message, messageChannel.port2);
    return completer.future;
  }

  /// Basic error handling, likely at initialization.
  Stream<Object> get onError;
}

/// Post message sender to shared worker.
class RawMessageSenderSharedWorker extends RawMessageSender {
  final web.SharedWorker _sharedWorker;

  web.MessagePort get _port => _sharedWorker.port;

  /// Post message sender to shared worker.
  RawMessageSenderSharedWorker(this._sharedWorker);

  @override
  void postMessage(Object message, web.MessagePort responsePort) {
    _port.postMessage(message.jsifyValueStrict(),
        messagePortToPortMessageOption(responsePort));
  }

  StreamController<Object>? _errorController;
  @override
  Stream<Object> get onError {
    if (_errorController == null) {
      var zone = Zone.current;
      _errorController = StreamController<Object>.broadcast(onListen: () {
        _sharedWorker.onerror = (web.Event event) {
          zone.run(() {
            _errorController!.add(event);
          });
        }.toJS;
      }, onCancel: () {
        _errorController = null;
        _sharedWorker.onerror = null;
      });
    }
    return _errorController!.stream;
  }
}

/// Post message sender to worker.
class RawMessageSenderToWorker extends RawMessageSender {
  final web.Worker _worker;

  StreamController<Object>? _errorController;

  @override
  Stream<Object> get onError {
    if (_errorController == null) {
      var zone = Zone.current;
      _errorController = StreamController<Object>.broadcast(onListen: () {
        _worker.onerror = (web.Event event) {
          zone.run(() {
            _errorController!.add(event);
          });
        }.toJS;
      }, onCancel: () {
        _errorController = null;
        _worker.onerror = null;
      });
    }
    return _errorController!.stream;
  }

  /// Post message sender to worker.
  RawMessageSenderToWorker(this._worker);

  @override
  void postMessage(Object message, web.MessagePort responsePort) {
    _worker.postMessage(message.jsifyValueStrict(),
        messagePortToPortMessageOption(responsePort));
  }
}
