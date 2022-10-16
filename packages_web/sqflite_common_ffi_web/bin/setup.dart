import 'dart:io';

import 'package:args/args.dart';
import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

Future<void> main(List<String> args) async {
  var parser = ArgParser()
    ..addFlag('force', abbr: 'f', help: 'Force build', defaultsTo: false)
    ..addFlag('verbose', help: 'Verbose output', defaultsTo: false)
    ..addFlag('help', help: 'Help')
    ..addOption('dir', help: 'output directory', defaultsTo: 'web');
  var result = parser.parse(args);
  var force = result['force'] as bool;
  var verbose = result['verbose'] as bool;
  var dir = result['dir'] as String?;
  var help = (result['help'] as bool?) ?? false;
  if (help) {
    stdout.writeln('Usage: ');
    stdout.writeln('  setup <options> <path>');
    stdout.writeln('Options: ');
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
      options:
          SetupOptions(path: path, dir: dir, force: force, verbose: verbose));
}
