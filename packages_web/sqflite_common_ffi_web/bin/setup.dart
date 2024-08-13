import 'dart:io';

import 'package:args/args.dart';
import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

var noSqlite3Wasm = 'no-sqlite3-wasm';
var sqlite3WasmUrl = 'sqlite3-wasm-url';

Future<void> main(List<String> args) async {
  var parser = ArgParser()
    ..addFlag('force', abbr: 'f', help: 'Force build', defaultsTo: false)
    ..addFlag('verbose', help: 'Verbose output', defaultsTo: false)
    ..addFlag('help', help: 'Help')
    ..addOption(sqlite3WasmUrl,
        help: 'sqlite3.wasm url', defaultsTo: '$sqlite3WasmReleaseUri')
    ..addFlag(noSqlite3Wasm,
        help: 'Don\'t fetch sqlite3.wasm', negatable: false, defaultsTo: false)
    ..addOption('dir', help: 'output directory', defaultsTo: 'web');
  var result = parser.parse(args);
  var force = result['force'] as bool;
  var verbose = result['verbose'] as bool;
  var dir = result['dir'] as String?;
  var sqlite3WasmUri = Uri.parse(result[sqlite3WasmUrl] as String);
  var help = (result['help'] as bool?) ?? false;
  if (help) {
    stdout.writeln('Build sqflite shared worker and fetch sqflite3.wasm.');
    stdout.writeln('\nUsage: ');
    stdout.writeln('  setup <options> <path>');
    stdout.writeln('\nOptions: ');
    stdout.writeln(parser.usage);
    await stdout.flush();
    exit(0);
  }
  if (result.rest.length > 1) {
    stderr.writeln('Only one argument (path) is supported');
    exit(1);
  }
  var path = result.rest.isNotEmpty ? result.rest.first : null;
  await webdevReady;
  await setupBinaries(
      options: SetupOptions(
          path: path,
          dir: dir,
          force: force,
          verbose: verbose,
          sqlite3WasmUri: sqlite3WasmUri,
          noSqlite3Wasm: result[noSqlite3Wasm] as bool));
}
