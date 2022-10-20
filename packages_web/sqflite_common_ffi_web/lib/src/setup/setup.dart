import 'dart:async';
import 'dart:io';

import 'package:dev_test/build_support.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sqflite_common_ffi_web/src/constant.dart';

// https://github.com/simolus3/sqlite3.dart/releases
var _sqlite3WasmVersion = Version(1, 9, 1);
var _sqlite3WasmReleaseUri = Uri.parse(
    'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$_sqlite3WasmVersion/sqlite3.wasm');

/// dhttpd simple server (testing only
var dhttpdReady = () async {
  // setup common alias
  shellEnvironment = ShellEnvironment()
    ..aliases['dhttpd'] = 'dart pub global run dhttpd';
  try {
    await run('dhttpd --help', verbose: false);
  } catch (e) {
    await run('dart pub global activate dhttpd');
  }
}();

/// webdev must be activated.
var webdevReady = () async {
  // setup common alias
  shellEnvironment = ShellEnvironment()
    ..aliases['webdev'] = 'dart pub global run webdev';
  try {
    await run('webdev --version', verbose: false);
  } catch (e) {
    await run('dart pub global activate webdev');
    await run('webdev --version');
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

  /// Don't fetch sqlite3 wasm
  late final bool noSqlite3Wasm;

  /// Setup options.
  SetupOptions(
      {String? path,
      String? dir,
      bool? force,
      bool? verbose,
      bool? noSqlite3Wasm}) {
    this.dir = dir ?? 'web';
    this.path = normalize(absolute(path ?? '.'));
    this.force = force ?? false;
    this.verbose = verbose ?? false;
    this.noSqlite3Wasm = noSqlite3Wasm ?? false;
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

  /// If overriden in pubspec
  final String? overridenSwJsFile;

  /// Setup Context.
  SetupContext(
      {required this.options,
      required this.ffiWebPath,
      required this.version,
      required this.overridenSwJsFile});
}

var _sourceBuild = 'web';
var _rawBuiltSharedWorkerJsFile = 'sqflite_sw.dart.js';

/// Easy path access
extension SetupContextExt on SetupContext {
  /// Working path for setup
  String get workPath => runningFromPackage
      ? path
      : join(path, '.dart_tool', packageName, 'setup', version.toString());

  /// Resulting shared worker file
  String get builtSwJsFilePath =>
      join(workPath, 'build', _rawBuiltSharedWorkerJsFile);

  /// running from ourself, skip copy
  bool get runningFromPackage =>
      (canonicalize(path) == canonicalize(ffiWebPath));

  /// Build shared worker.
  Future build() async {
    var force = options.force;

    var needBuild = force;
    if (!needBuild) {
      if (!File(builtSwJsFilePath).existsSync()) {
        needBuild = true;
      }
    }
    if (needBuild) {
      print('Building $packageName shared worker');

      if (force) {
        if (!runningFromPackage) {
          await deleteDirectory(workPath);
        }
      }
      var shell = Shell(workingDirectory: workPath);
      print(shell.path);
      if (!runningFromPackage) {
        await Directory(workPath).create(recursive: true);
        await copySourcesPath(ffiWebPath, workPath);
      }

      await shell.run('dart pub get');
      await shell.run('webdev build -o $_sourceBuild:build');
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
      var swJsFile = overridenSwJsFile ?? sqfliteSharedWorkerJsFile;
      var sqfliteSwJsOutFile = join(out, swJsFile);
      await File(builtSwJsFilePath).copy(sqfliteSwJsOutFile);

      var wasmFile = join(out, sqlite3WasmFile);
      if (!options.noSqlite3Wasm) {
        var uri = _sqlite3WasmReleaseUri;
        print('Fetching: $uri');
        var wasmBytes = await readBytes(uri);
        await File(wasmFile).writeAsBytes(wasmBytes);
      }

      print(
          'created: $sqfliteSwJsOutFile (${File(sqfliteSwJsOutFile).statSync().size} bytes)');
      if (!options.noSqlite3Wasm) {
        print('created: $wasmFile (${File(wasmFile).statSync().size} bytes)');
      }
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
  // sqflite:
  //   # Update for force changing file name for shared worker
  //   # to force an app update until a better solution is found
  //   # default being sqflite_sw.ja
  //   # Could be sqflite_sw_v1.js
  //   # Re run setup
  //   sqflite_common_ffi_web:
  //     sw_js_file: sqflite_sw_v1.js
  var overridenSwJsFile =
      ((pubspec['sqflite'] as Map?)?[packageName] as Map?)?['sw_js_file']
          ?.toString();

  var ffiWebPath =
      pathPackageConfigMapGetPackagePath(path, config, packageName)!;

  ffiWebPath = absolute(normalize(ffiWebPath));
  var ffiPubspec = await pathGetPubspecYamlMap(path);
  var version = pubspecYamlGetVersion(ffiPubspec);
  return SetupContext(
      options: options,
      ffiWebPath: ffiWebPath,
      version: version,
      overridenSwJsFile: overridenSwJsFile);
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
  await webdevReady;
  var context = await getSetupContext(options: options);

  await context.build();
  await context.copyBinaries();
}

bool _doNothing(String from, String to) {
  if (p.canonicalize(from) == p.canonicalize(to)) {
    return true;
  }
  if (p.isWithin(from, to)) {
    throw ArgumentError('Cannot copy from $from to $to');
  }
  return false;
}

bool _topLevelFileShouldIgnore(String path) {
  // devPrint(path);
  var name = basename(path);
  if (name.startsWith('.')) {
    return true;
  }
  if (name == 'build') {
    return true;
  }
  if (extension(name).endsWith('.iml')) {
    return true;
  }
  // devPrint('ok');
  return false;
}

/// Copies all of the files in the [from] directory to [to].
///
/// This is similar to `cp -R <from> <to>`:
/// * Symlinks are supported.
/// * Existing files are over-written, if any.
/// * If [to] is within [from], throws [ArgumentError] (an infinite operation).
/// * If [from] and [to] are canonically the same, no operation occurs.
///
/// Returns a future that completes when complete.
Future<void> copySourcesPath(String from, String to) async {
  if (_doNothing(from, to)) {
    return;
  }
  await Directory(to).create(recursive: true);
  await for (final file in Directory(from)
      .list(recursive: false)
      .where((event) => !_topLevelFileShouldIgnore(event.path))) {
    final copyTo = p.join(to, p.relative(file.path, from: from));
    if (file is Directory) {
      await Directory(copyTo).create(recursive: true);
      await copySourcesPath(
          join(from, basename(file.path)), join(to, basename(file.path)));
    } else if (file is File) {
      await File(file.path).copy(copyTo);
    } else if (file is Link) {
      await Link(copyTo).create(await file.target(), recursive: true);
    }
  }
}
