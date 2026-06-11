/// Stub send port definition to avoid importing `dart:isolate` which is
/// not supported on the web.
abstract class SendPort {}

/// Interface to share the sqflite isolate send port between isolates.
///
/// Typically implemented using Flutter `IsolateNameServer` (see the
/// `sqflite_ffi` package) so that a single sqflite isolate is shared
/// by all the isolates of an application.
///
/// Not supported on the web (there is no sqflite isolate to share).
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
