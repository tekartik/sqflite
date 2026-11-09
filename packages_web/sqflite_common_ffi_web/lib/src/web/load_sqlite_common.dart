import 'package:meta/meta.dart';

/// Options of a web factory, see `createDatabaseFactoryFfiWeb`.
///
/// All are optional, the defaults match the files created by
/// `dart run sqflite_common_ffi_web:setup` next to the page.
class SqfliteFfiWebOptions {
  /// Web factory options.
  SqfliteFfiWebOptions({
    this.inMemory,
    this.sqlite3WasmUri,
    this.indexedDbName,
    this.sharedWorkerUri,
    @visibleForTesting this.forceAsBasicWorker,
  });

  /// True to keep the databases in memory only (nothing persisted,
  /// [indexedDbName] is ignored).
  final bool? inMemory;

  /// The sqlite3.wasm url (default `sqlite3.wasm`, relative to the worker
  /// script, or to the page without worker).
  final Uri? sqlite3WasmUri;

  /// The IndexedDB database holding the databases (default
  /// `sqflite_databases`).
  final String? indexedDbName;

  /// The worker script url (default `sqflite_sw.js`, relative to the page).
  ///
  /// A shared worker serves every factory and tab using this url and keeps
  /// the options of its first use: use another file name for other options.
  final Uri? sharedWorkerUri;

  /// Force sharedWorkerUri as a basic worker (i.e. Worker instead of SharedWorker).
  /// Shared worker don't work on Android mobile web yet.
  final bool? forceAsBasicWorker;

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
  /// Options always present.
  SqfliteFfiWebContext({required this.options});

  /// Context options.
  final SqfliteFfiWebOptions options;
}
