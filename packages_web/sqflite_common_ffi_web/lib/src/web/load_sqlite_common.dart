import 'package:meta/meta.dart';

/// Web options.
class SqfliteFfiWebOptions {
  /// In memory options, indexedDbName is ignored
  final bool? inMemory;

  /// wasm3 uri
  final Uri? sqlite3WasmUri;

  /// Indexed db name holder the databases.
  final String? indexedDbName;

  /// If using a shared worker, the one to spawn.
  final Uri? sharedWorkerUri;

  /// Force sharedWorkerUri as a basic worker (i.e. Worker instead of SharedWorker).
  /// Shared worker don't work on Android mobile web yet.
  final bool? forceAsBasicWorker;

  /// Default ok for regular dart applications but not flutter app.
  SqfliteFfiWebOptions(
      {this.inMemory,
      this.sqlite3WasmUri,
      this.indexedDbName,
      this.sharedWorkerUri,
      @visibleForTesting this.forceAsBasicWorker});
}

/// Abstract context for the web (holder file system and wasm)
abstract class SqfliteFfiWebContext {
  /// Context options.
  final SqfliteFfiWebOptions options;

  /// Options always present.
  SqfliteFfiWebContext({required this.options});
}
