// Setup the web binaries needed by sqflite_common_ffi_async.
//
// Follow the steps on https://pub.dev/documentation/sqlite_async/latest/
//
// The compiled web worker file (db_worker.js) can be found in the sqlite_async
// Github releases (https://github.com/powersync-ja/sqlite_async.dart/releases)
// and the sqlite3.wasm asset in the sqlite3.dart Github releases
// (https://github.com/simolus3/sqlite3.dart/releases). Both must be placed in
// the web folder of the project.
//
// Usage:
//   dart run tool/setup_ffi_async.dart [options] [path]
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

/// Github repository holding the sqlite3.wasm releases.
const sqlite3Repo = 'simolus3/sqlite3.dart';

/// Github repository holding the sqlite_async web worker releases.
const sqliteAsyncRepo = 'powersync-ja/sqlite_async.dart';

/// sqlite3 wasm asset (and destination file) name.
const sqlite3WasmFile = 'sqlite3.wasm';

/// sqlite_async web worker asset (and destination file) name.
///
/// Must match the `workerUri` used in sqflite_common_ffi_async.
const dbWorkerJsFile = 'db_worker.js';

/// Where downloaded assets are cached, relative to the project path.
final downloadDir = join('.local', 'sqflite_common_ffi_async');

/// Metadata file (in [downloadDir]) tracking what was last copied.
const metadataFile = 'sqflite_ffi_async_meta.json';

var _log = stdout.writeln;

/// A single release asset (one file in one Github release).
class ReleaseAsset {
  /// A single release asset.
  ///
  /// [repo] is the `owner/name` Github repository, [tag] the release tag
  /// (i.e. `sqlite3-3.5.1`), [name] the asset file name and [downloadUri]
  /// where its content can be fetched.
  ReleaseAsset({
    required this.repo,
    required this.tag,
    required this.name,
    required this.downloadUri,
  });

  /// Github repository (`owner/name`).
  final String repo;

  /// Release tag.
  final String tag;

  /// Asset (file) name.
  final String name;

  /// Asset download uri.
  final Uri downloadUri;

  /// Release page uri, for display purpose.
  Uri get releaseUri => Uri.parse('https://github.com/$repo/releases/tag/$tag');

  /// Cached file path in [downloadDir], one folder per repository and tag.
  String cachedFilePath(String path) =>
      join(path, downloadDir, repo.replaceAll('/', '_'), tag, name);

  /// Json map representation, used for metadata comparison.
  Map<String, Object?> toJsonMap() => {'repo': repo, 'tag': tag, 'name': name};

  @override
  String toString() => '$repo $tag $name';
}

/// Metadata of the last successful setup.
class SetupMetadata {
  /// Metadata of the last successful setup.
  ///
  /// [dir] is the destination directory (relative to the project path),
  /// [assets] the description of each copied asset.
  SetupMetadata({required this.dir, required this.assets});

  /// Read from a json map, as written by [toJsonMap].
  factory SetupMetadata.fromJsonMap(Map map) {
    return SetupMetadata(
      dir: map['dir']?.toString() ?? 'web',
      assets: ((map['assets'] as List?) ?? <Object?>[])
          .map((asset) => Map<String, Object?>.from(asset as Map))
          .toList(),
    );
  }

  /// Destination directory, relative to the project path.
  final String dir;

  /// Copied assets, as returned by [ReleaseAsset.toJsonMap].
  final List<Map<String, Object?>> assets;

  /// Json map representation.
  Map<String, Object?> toJsonMap() => {'dir': dir, 'assets': assets};

  @override
  String toString() => jsonEncode(toJsonMap());
}

/// Github api client, using `GITHUB_TOKEN` when available to raise the
/// anonymous rate limit.
Future<Object?> _githubApiGetJson(Uri uri, {required bool verbose}) async {
  if (verbose) {
    _log('GET $uri');
  }
  var token = Platform.environment['GITHUB_TOKEN'];
  var response = await http.get(
    uri,
    headers: {
      'Accept': 'application/vnd.github+json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode != 200) {
    throw StateError(
      'Github api error ${response.statusCode} on $uri: ${response.body}',
    );
  }
  return jsonDecode(response.body);
}

/// Find the asset [assetName] in the [repo] releases.
///
/// When [tag] is null, the most recent release containing [assetName] is used
/// (the repositories are mono-repos, the latest release might be for another
/// package). Throws a [StateError] when the asset cannot be found.
Future<ReleaseAsset> findReleaseAsset(
  String repo,
  String assetName, {
  String? tag,
  bool verbose = false,
}) async {
  List<Object?> releases;
  if (tag != null) {
    var release = await _githubApiGetJson(
      Uri.parse('https://api.github.com/repos/$repo/releases/tags/$tag'),
      verbose: verbose,
    );
    releases = [release];
  } else {
    releases =
        (await _githubApiGetJson(
                  Uri.parse(
                    'https://api.github.com/repos/$repo/releases?per_page=50',
                  ),
                  verbose: verbose,
                )
                as List)
            .cast<Object?>();
  }
  for (var release in releases.cast<Map>()) {
    if (release['draft'] == true) {
      continue;
    }
    var releaseTag = release['tag_name'].toString();
    for (var asset in ((release['assets'] as List?) ?? []).cast<Map>()) {
      if (asset['name'] == assetName) {
        return ReleaseAsset(
          repo: repo,
          tag: releaseTag,
          name: assetName,
          downloadUri: Uri.parse(asset['browser_download_url'].toString()),
        );
      }
    }
    if (tag != null) {
      throw StateError('Asset $assetName not found in $repo release $tag');
    }
  }
  throw StateError('Asset $assetName not found in the $repo releases');
}

/// Download [asset] to its cached location unless already there.
///
/// Returns the cached file. Re-download happens when [force] is true.
Future<File> downloadAsset(
  ReleaseAsset asset, {
  required String path,
  required bool force,
  required bool verbose,
}) async {
  var file = File(asset.cachedFilePath(path));
  if (file.existsSync() && !force) {
    if (verbose) {
      _log('cached: ${file.path} (${file.statSync().size} bytes)');
    }
    return file;
  }
  _log('Fetching: ${asset.downloadUri}');
  var bytes = await http.readBytes(asset.downloadUri);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  _log('downloaded: ${file.path} (${bytes.length} bytes)');
  return file;
}

/// Download and copy the sqflite_common_ffi_async web binaries.
///
/// [path] is the project path, [dir] the destination directory relative to it
/// (`web` by default). [wasmTag] and [workerTag] allow pinning a release tag
/// for sqlite3.wasm and db_worker.js, the latest release is used when null.
/// [force] re-downloads even when the files are up to date.
Future<void> setupFfiAsyncBinaries({
  required String path,
  required String dir,
  String? wasmTag,
  String? workerTag,
  bool force = false,
  bool verbose = false,
}) async {
  var wasmAsset = await findReleaseAsset(
    sqlite3Repo,
    sqlite3WasmFile,
    tag: wasmTag,
    verbose: verbose,
  );
  var workerAsset = await findReleaseAsset(
    sqliteAsyncRepo,
    dbWorkerJsFile,
    tag: workerTag,
    verbose: verbose,
  );
  var assets = [wasmAsset, workerAsset];
  for (var asset in assets) {
    _log('${asset.name}: ${asset.tag} (${asset.releaseUri})');
  }

  var metadata = SetupMetadata(
    dir: dir,
    assets: assets.map((asset) => asset.toJsonMap()).toList(),
  );
  var metadataFilePath = join(path, downloadDir, metadataFile);
  var outDir = join(path, dir);

  if (!force) {
    SetupMetadata? currentMetadata;
    try {
      var file = File(metadataFilePath);
      if (file.existsSync()) {
        currentMetadata = SetupMetadata.fromJsonMap(
          jsonDecode(await file.readAsString()) as Map,
        );
      }
    } catch (e) {
      _log('Failed to read $metadataFilePath: $e');
    }
    var upToDate =
        currentMetadata != null &&
        jsonEncode(currentMetadata.toJsonMap()) ==
            jsonEncode(metadata.toJsonMap()) &&
        assets.every((asset) => File(join(outDir, asset.name)).existsSync());
    if (upToDate) {
      _log('sqflite_common_ffi_async web binaries up to date in $outDir');
      _log('Use --force to download them again.');
      return;
    }
    if (verbose && currentMetadata != null) {
      _log('Metadata changed (new: $metadata, old: $currentMetadata)');
    }
  }

  await Directory(outDir).create(recursive: true);
  for (var asset in assets) {
    var cachedFile = await downloadAsset(
      asset,
      path: path,
      force: force,
      verbose: verbose,
    );
    var outFile = join(outDir, asset.name);
    await cachedFile.copy(outFile);
    _log('created: $outFile (${File(outFile).statSync().size} bytes)');
  }

  var metadataFileOut = File(metadataFilePath);
  await metadataFileOut.parent.create(recursive: true);
  await metadataFileOut.writeAsString(jsonEncode(metadata.toJsonMap()));
  if (verbose) {
    _log('written: $metadataFilePath');
  }
}

/// Setup the sqflite_common_ffi_async web binaries.
Future<void> main(List<String> args) async {
  var parser = ArgParser()
    ..addFlag(
      'force',
      abbr: 'f',
      help: 'Force download even if up to date',
      defaultsTo: false,
    )
    ..addFlag('verbose', abbr: 'v', help: 'Verbose output', defaultsTo: false)
    ..addFlag('help', abbr: 'h', help: 'Help', negatable: false)
    ..addOption(
      'wasm-tag',
      help: 'sqlite3.dart release tag for $sqlite3WasmFile (default: latest)',
    )
    ..addOption(
      'worker-tag',
      help:
          'sqlite_async.dart release tag for $dbWorkerJsFile (default: latest)',
    )
    ..addOption('dir', help: 'output directory', defaultsTo: 'web');
  var result = parser.parse(args);
  if (result['help'] as bool) {
    stdout.writeln(
      'Fetch $dbWorkerJsFile and $sqlite3WasmFile needed by '
      'sqflite_common_ffi_async on the web.',
    );
    stdout.writeln('\nUsage: ');
    stdout.writeln('  dart run tool/setup_ffi_async.dart <options> <path>');
    stdout.writeln('\nOptions: ');
    stdout.writeln(parser.usage);
    await stdout.flush();
    exit(0);
  }
  if (result.rest.length > 1) {
    stderr.writeln('Only one argument (path) is supported');
    exit(1);
  }
  var path = normalize(
    absolute(result.rest.isNotEmpty ? result.rest.first : '.'),
  );
  await setupFfiAsyncBinaries(
    path: path,
    dir: result['dir'] as String,
    wasmTag: result['wasm-tag'] as String?,
    workerTag: result['worker-tag'] as String?,
    force: result['force'] as bool,
    verbose: result['verbose'] as bool,
  );
}
