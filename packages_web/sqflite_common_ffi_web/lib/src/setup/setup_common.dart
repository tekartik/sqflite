// https://github.com/simolus3/sqlite3.dart/releases
import 'package:path/path.dart';

import 'sqlite3_wasm_version.dart';

/// sqlite3 wasm release
var sqlite3WasmReleaseUri = Uri.parse(
  'https://github.com/simolus3/sqlite3.dart/releases/download/$sqlite3WasmRelease',
);

/// Setup options.
class SqfliteWebSetupOptions {
  /// Project path (current directory by default). absolute
  late final String path;

  /// Directory (web by default). relative
  late final String dir;

  /// If true a clean build is made.
  late final bool force;

  /// Verbose mode.
  late final bool verbose;

  /// Don't fetch sqlite3 wasm
  late final bool noSqlite3Wasm;

  /// Sqlite3 wasm uri
  late final Uri sqlite3WasmUri;

  /// Sqlite3 wasm local file (default to sqlite3.wasm)
  final String? sqlite3WasmFilename;

  /// Web worker local file (default to sqflite_sw.js or read from pubspec)
  final String? sqfliteWebWorkerFilename;

  /// Setup options.
  SqfliteWebSetupOptions({
    String? path,
    String? dir,
    bool? force,
    bool? verbose,
    Uri? sqlite3WasmUri,
    bool? noSqlite3Wasm,
    this.sqlite3WasmFilename,
    this.sqfliteWebWorkerFilename,
  }) {
    this.dir = dir ?? 'web';
    this.path = normalize(absolute(path ?? '.'));
    this.force = force ?? false;
    this.verbose = verbose ?? false;
    this.noSqlite3Wasm = noSqlite3Wasm ?? false;
    this.sqlite3WasmUri = sqlite3WasmUri ?? sqlite3WasmReleaseUri;
    assert(isRelative(this.dir));
  }
}

/// Exported for setup, compat
typedef SetupOptions = SqfliteWebSetupOptions;
