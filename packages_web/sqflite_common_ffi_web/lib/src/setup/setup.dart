import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sqflite_common_ffi_web/src/constant.dart';

import 'sqlite3_wasm_version.dart';

var _log = print;
// https://github.com/simolus3/sqlite3.dart/releases
/// sqlite3 wasm release
var sqlite3WasmReleaseUri = Uri.parse(
    'https://github.com/simolus3/sqlite3.dart/releases/download/$sqlite3WasmRelease');

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
  await checkAndActivateWebdev();
  // setup common alias
  shellEnvironment = ShellEnvironment()
    ..aliases['webdev'] = 'dart pub global run webdev';
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

  /// Sqlite3 wasm uri
  late final Uri sqlite3WasmUri;

  /// Setup options.
  SetupOptions(
      {String? path,
      String? dir,
      bool? force,
      bool? verbose,
      Uri? sqlite3WasmUri,
      bool? noSqlite3Wasm}) {
    this.dir = dir ?? 'web';
    this.path = normalize(absolute(path ?? '.'));
    this.force = force ?? false;
    this.verbose = verbose ?? false;
    this.noSqlite3Wasm = noSqlite3Wasm ?? false;
    this.sqlite3WasmUri = sqlite3WasmUri ?? sqlite3WasmReleaseUri;
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

/// Meta data file
var sqfliteWebMetadataFile = 'sqflite_web_meta.json';

/// Sqflite web metadata
class SqfliteWebMetadata {
  /// Version
  final Version? version;

  /// sqlite3.wasm uri
  final Uri? sqlite3WasmUri;

  /// Sqflite web metadata
  SqfliteWebMetadata({this.version, this.sqlite3WasmUri});

  /// To json map
  Map<String, Object?> toJsonMap() {
    return {
      'version': version?.toString(),
      'sqlite3WasmUri': sqlite3WasmUri?.toString(),
    };
  }

  @override
  int get hashCode =>
      (version?.hashCode ?? 0) + (sqlite3WasmUri?.hashCode ?? 0);

  @override
  bool operator ==(Object other) {
    if (other is SqfliteWebMetadata) {
      return version == other.version && sqlite3WasmUri == other.sqlite3WasmUri;
    }
    return false;
  }

  /// From json map
  SqfliteWebMetadata.fromJsonMap(Map map)
      : version = map['version'] != null
            ? Version.parse(map['version'] as String)
            : null,
        sqlite3WasmUri = map['sqlite3WasmUri'] != null
            ? Uri.parse(map['sqlite3WasmUri'] as String)
            : null;

  @override
  String toString() => '${toJsonMap()}';
}

/// Easy path access
extension SetupContextExt on SetupContext {
  /// Working path for setup
  String get workPath => runningFromPackage
      ? path
      : join(path, '.dart_tool', packageName, 'setup', version.toString());

  /// Resulting shared worker file
  String get builtSwJsFilePath =>
      join(workPath, 'build', _rawBuiltSharedWorkerJsFile);

  /// Resulting metadata file
  String get metadataFilePath =>
      join(workPath, 'build', sqfliteWebMetadataFile);

  /// running from ourself, skip copy
  bool get runningFromPackage =>
      (canonicalize(path) == canonicalize(ffiWebPath));

  /// Build shared worker.
  Future build() async {
    var force = options.force;
    var verbose = options.verbose;

    var metadata = SqfliteWebMetadata(
        version: version, sqlite3WasmUri: options.sqlite3WasmUri);
    var needBuild = force;
    var metadataFile = File(metadataFilePath);
    if (!needBuild) {
      SqfliteWebMetadata? currentMetadata;

      try {
        if (metadataFile.existsSync()) {
          currentMetadata = SqfliteWebMetadata.fromJsonMap(
              jsonDecode(await File(metadataFilePath).readAsString()) as Map);
        }
      } catch (e) {
        _log('Failed to read $sqfliteWebMetadataFile: $e');
      }
      if (currentMetadata != metadata) {
        if (verbose) {
          _log('Metadata changed (new: $metadata, old: $currentMetadata)');
        }
        needBuild = true;
      }

      if (!needBuild) {
        if (!File(builtSwJsFilePath).existsSync()) {
          needBuild = true;
        }
      }
    }
    if (needBuild) {
      _log('Building $packageName shared worker');

      if (force) {
        if (!runningFromPackage) {
          await deleteDirectory(workPath);
        }
      }

      if (!runningFromPackage) {
        await Directory(workPath).create(recursive: true);
        await copySourcesPath(ffiWebPath, workPath);
        shellEnvironment = ShellEnvironment()
          ..aliases['webdev'] = 'dart run webdev:webdev';
      }
      var shell = Shell(workingDirectory: workPath, verbose: options.verbose);
      _log(shell.path);

      if (!runningFromPackage) {
        // Add local webdev package
        await shell.run('dart pub add dev:webdev');
      }
      await shell.run('dart pub get');
      await shell.run('webdev build -o $_sourceBuild:build');
      if (verbose) {
        _log('Writing meta ${metadataFile.path} $metadata');
      }
      await metadataFile.writeAsString(jsonEncode(metadata.toJsonMap()));
    } else {
      if (verbose) {
        _log('metadata $metadata ok');
      }
      _log('$packageName binaries up to date');
    }
  }

  /// Copy generated binaries to the current project web folder.
  Future<void> copyBinaries() async {
    var out = join(path, options.dir);
    await Directory(out).create(recursive: true);

    // Prevent conflicting output for ourself
    // Prevent conflicting output for ourself
    if (File(join(out, 'sqflite_sw.dart')).existsSync()) {
      _log('no files created here, we are the generator');
    } else {
      var swJsFile = overridenSwJsFile ?? sqfliteSharedWorkerJsFile;
      var sqfliteSwJsOutFile = join(out, swJsFile);
      await File(builtSwJsFilePath).copy(sqfliteSwJsOutFile);

      var wasmFile = join(out, sqlite3WasmFile);
      if (!options.noSqlite3Wasm) {
        var uri = sqlite3WasmReleaseUri;
        _log('Fetching: $uri');
        var wasmBytes = await readBytes(uri);
        await File(wasmFile).writeAsBytes(wasmBytes);
      }

      _log(
          'created: $sqfliteSwJsOutFile (${File(sqfliteSwJsOutFile).statSync().size} bytes)');
      if (!options.noSqlite3Wasm) {
        _log('created: $wasmFile (${File(wasmFile).statSync().size} bytes)');
      }
    }
  }
}

/// Our package name.
var packageName = 'sqflite_common_ffi_web';

/// Get the the setup context in a given directory
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
  var ffiWebPubspec = await pathGetPubspecYamlMap(ffiWebPath);
  var version = pubspecYamlGetVersion(ffiWebPubspec);
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

/// Exported for setup
typedef SqfliteWebSetupOptions = SetupOptions;

/// Exported for setup
Future<void> setupSqfliteWebBinaries({SqfliteWebSetupOptions? options}) async {
  await setupBinaries(options: options);
}

/// Build and copy the binaries
Future<void> setupBinaries({SetupOptions? options}) async {
  var context = await getSetupContext(options: options);
  if (context.runningFromPackage) {
    _log(
        'Running from package, use global webdev, this should only be printed when running from sqflite_common_ffi_web, i.e. during development');
    await webdevReady;
  }
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
