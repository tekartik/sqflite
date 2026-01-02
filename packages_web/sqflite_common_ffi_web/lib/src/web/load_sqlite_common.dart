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
  SqfliteFfiWebOptions({
    this.inMemory,
    this.sqlite3WasmUri,
    this.indexedDbName,
    this.sharedWorkerUri,
    @visibleForTesting this.forceAsBasicWorker,
  });

  @override
  String toString() {
    return 'SqfliteFfiWebOptions(inMemory: $inMemory, sqlite3WasmUri: $sqlite3WasmUri, indexedDbName: $indexedDbName, sharedWorkerUri: $sharedWorkerUri, forceAsBasicWorker: $forceAsBasicWorker)';
  }
}

/// Extension to convert to map (private)
extension SqfliteFfiWebOptionsExt on SqfliteFfiWebOptions {
  /// Convert to map.
  Map<String, Object?> toMap() {
    return {
      'inMemory': inMemory,
      'sqlite3WasmUri': sqlite3WasmUri?.toString(),
      'indexedDbName': indexedDbName,
      'sharedWorkerUri': sharedWorkerUri?.toString(),
      'forceAsBasicWorker': forceAsBasicWorker,
    };
  }
}

/// Create options from map.
SqfliteFfiWebOptions sqfliteFfiWebOptionsFromMap(Map map) {
  var sqlite3WasmUri = map['sqlite3WasmUri'] as String?;
  var indexedDbName = map['indexedDbName'] as String?;
  var sharedWorkerUri = map['sharedWorkerUri'] as String?;
  var forceAsBasicWorker = map['forceAsBasicWorker'] as bool?;
  var inMemory = map['inMemory'] as bool?;
  return SqfliteFfiWebOptions(
    inMemory: inMemory,
    sqlite3WasmUri: sqlite3WasmUri != null ? Uri.parse(sqlite3WasmUri) : null,
    indexedDbName: indexedDbName,
    sharedWorkerUri: sharedWorkerUri != null
        ? Uri.parse(sharedWorkerUri)
        : null,
    forceAsBasicWorker: forceAsBasicWorker,
  );
}

/// Abstract context for the web (holder file system and wasm)
abstract class SqfliteFfiWebContext {
  /// Context options.
  final SqfliteFfiWebOptions options;

  /// Options always present.
  SqfliteFfiWebContext({required this.options});
}
