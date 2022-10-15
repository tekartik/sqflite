import 'dart:io';

import 'package:dev_test/build_support.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

var _sqlite3WasmReleaseUri = Uri.parse(
    'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-1.9.0/sqlite3.wasm');

/// webdev must be activated.
var webdevReady = () async {
  var shell = Shell();
  try {
    await shell.run('dart pub global run webdev --version');
  } catch (e) {
    await shell.run('dart pub global activate webdev');
  }
}();

/// Setup context
class SetupContext {
  /// Project shell.
  late final ffiWebShell = Shell(
      workingDirectory: ffiWebPath,
      environment: ShellEnvironment()
        ..aliases['webdev'] = 'dart pub global run webdev');

  /// Project path
  final String path;

  /// Ffi web path
  final String ffiWebPath;

  /// Setup Context.
  SetupContext({required this.path, required this.ffiWebPath});

  /// Copy generated binaries to the current project web folder.
  Future<void> copyBinaries({String? outputDir}) async {
    var context = await getSetupContext();
    // outputDir ??= join('web', 'sqflite');
    outputDir ??= join('web');
    var out = join(context.path, outputDir);
    await Directory(out).create(recursive: true);

    // Prevent conflicting output for ourself
    if (!File(join(out, 'sqflite_sw.dart')).existsSync()) {
      var swFile = join(out, 'sqflite_sw.dart.js');
      await File(join(context.ffiWebPath, 'build', 'sqflite_sw.dart.js'))
          .copy(swFile);
      print('created: $swFile');
      var swMapFile = join(out, 'sqflite_sw.dart.js.map');
      await File(join(context.ffiWebPath, 'build', 'sqflite_sw.dart.js.map'))
          .copy(swMapFile);
      print('created: $swMapFile');

      var wasmBytes = await readBytes(_sqlite3WasmReleaseUri);
      var wasmFile = join(out, 'sqlite3.wasm');
      await File(wasmFile).writeAsBytes(wasmBytes);
      print('created: $wasmFile');
    } else {
      print('no file created here, we are the generator');
    }
  }
}

/// Get the teh setup context in a given directory
Future<SetupContext> getSetupContext([String path = '.']) async {
  path = absolute(normalize(path));
  var config = await pathGetPackageConfigMap(path);
  var ffiWebPath = pathPackageConfigMapGetPackagePath(
      path, config, 'sqflite_common_ffi_web')!;
  ffiWebPath = absolute(normalize(ffiWebPath));
  return SetupContext(path: path, ffiWebPath: ffiWebPath);
}

Future<void> main() async {
  await webdevReady;
  await setupBinaries();
}

/// Build and copy the binaries
Future<void> setupBinaries([String path = '.']) async {
  var context = await getSetupContext(path);
  var shell = context.ffiWebShell;
  print(shell.path);
  await shell.run('dart pub get');
  try {
    await Directory('build').delete(recursive: true);
  } catch (e) {}
  await shell.run('webdev build -o web:build');

  await context.copyBinaries();
}
