import 'dart:io';

import 'package:dev_test/build_support.dart';
import 'package:http/http.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sqflite_common_ffi_web/src/constant.dart';

var _sqlite3WasmVersion = Version(1, 9, 0);
var _sqlite3WasmReleaseUri = Uri.parse(
    'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$_sqlite3WasmVersion/sqlite3.wasm');

/// webdev must be activated.
var webdevReady = () async {
  try {
    await run('webdev --version', verbose: false);
  } catch (e) {
    await run('dart pub global activate webdev');
  }
}();

/// Setup options.
class SetupOptions {
  /// Project path (current directory by default). absolute
  late final String path;

  /// Directory (web by default). relative
  late final String dir;

  /// If true a clean build is made.
  late final bool force;

  /// Verbose mode.
  late final bool verbose;

  /// Setup options.
  SetupOptions({String? path, String? dir, bool? force, bool? verbose}) {
    this.dir = dir ?? 'web';
    this.path = normalize(absolute(path ?? '.'));
    this.force = force ?? false;
    this.verbose = verbose ?? false;
    assert(isRelative(this.dir));
  }
}

/// Setup context
class SetupContext {
  /// The options.
  final SetupOptions options;

  /// Project path
  String get path => options.path;

  /// Ffi web path
  final String ffiWebPath;

  /// Version.
  final Version version;

  /// Setup Context.
  SetupContext(
      {required this.options, required this.ffiWebPath, required this.version});
}

/// Easy path access
extension SetupContextExt on SetupContext {
  /// Working path for setup
  String get workPath => runningFromPackage
      ? path
      : join(path, '.dart_tool', packageName, 'setup', version.toString());

  /// Resulting service worker file
  String get builtSwJsFilePath => join(workPath, 'build', 'sqflite_sw.dart.js');

  /// running from ourself, skip copy
  bool get runningFromPackage =>
      (canonicalize(path) == canonicalize(ffiWebPath));

  /// Build service worker.
  Future build() async {
    var force = options.force;

    var needBuild = force;
    if (!needBuild) {
      if (!File(builtSwJsFilePath).existsSync()) {
        needBuild = true;
      }
    }
    if (needBuild) {
      print('Building $packageName service worker');

      if (force) {
        if (!runningFromPackage) {
          await deleteDirectory(workPath);
        }
      }
      var shell = Shell(workingDirectory: workPath);
      print(shell.path);
      if (!runningFromPackage) {
        await Directory(workPath).create(recursive: true);
        await copyPath(ffiWebPath, workPath);
      }

      await shell.run('dart pub get');
      await shell.run('webdev build -o web:build');
    } else {
      print('$packageName binaries up to date');
    }
  }

  /// Copy generated binaries to the current project web folder.
  Future<void> copyBinaries() async {
    var out = join(path, options.dir);
    await Directory(out).create(recursive: true);

    // Prevent conflicting output for ourself
    // Prevent conflicting output for ourself
    if (File(join(out, 'sqflite_sw.dart')).existsSync()) {
      print('no files created here, we are the generator');
    } else {
      var sqfliteSwJsOutFile = join(out, sqfliteSwJsFile);

      await File(builtSwJsFilePath).copy(sqfliteSwJsOutFile);
      print(
          'created: $sqfliteSwJsOutFile (${File(sqfliteSwJsOutFile).statSync().size} bytes)');

      var wasmBytes = await readBytes(_sqlite3WasmReleaseUri);
      var wasmFile = join(out, sqlite3WasmFile);
      await File(wasmFile).writeAsBytes(wasmBytes);
      print('created: $wasmFile');
    }
  }
}

/// Our package name.
var packageName = 'sqflite_common_ffi_web';

/// Get the teh setup context in a given directory
Future<SetupContext> getSetupContext({SetupOptions? options}) async {
  options ??= SetupOptions();
  var path = options.path;
  var config = await pathGetPackageConfigMap(path);
  var pubspec = await pathGetPubspecYamlMap(path);
  var version = pubspecYamlGetVersion(pubspec);
  var ffiWebPath =
      pathPackageConfigMapGetPackagePath(path, config, packageName)!;

  ffiWebPath = absolute(normalize(ffiWebPath));
  return SetupContext(
      options: options, ffiWebPath: ffiWebPath, version: version);
}

Future<void> main() async {
  await webdevReady;
  await setupBinaries();
}

/// Safe delete a directory
Future<void> deleteDirectory(String path) async {
  try {
    await Directory(path).delete(recursive: true);
  } catch (_) {}
}

/// Build and copy the binaries
Future<void> setupBinaries({SetupOptions? options}) async {
  // Common alias
  shellEnvironment = ShellEnvironment()
    ..aliases['webdev'] = 'dart pub global run webdev';
  await webdevReady;
  var context = await getSetupContext(options: options);

  await context.build();
  await context.copyBinaries();
}
