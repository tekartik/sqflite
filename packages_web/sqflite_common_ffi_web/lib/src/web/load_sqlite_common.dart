/// Web options.
class SqfliteFfiWebOptions {
  /// In memory options, indexedDbName is ignored
  final bool? inMemory;

  /// wasm3 uri
  final Uri? sqlite3WasmUri;

  /// Indexed db name holder the databases.
  final String? indexedDbName;

  /// If using a service worker, the one to spawn.
  final Uri? serviceWorkerUri;

  /// Default ok for regular dart applications but not flutter app.
  SqfliteFfiWebOptions(
      {this.inMemory,
      this.sqlite3WasmUri,
      this.indexedDbName,
      this.serviceWorkerUri});
}

/// Abstract context for the web (holder file system and wasm)
abstract class SqfliteFfiWebContext {
  /// Context options.
  final SqfliteFfiWebOptions options;

  /// Options always present.
  SqfliteFfiWebContext({required this.options});
}
