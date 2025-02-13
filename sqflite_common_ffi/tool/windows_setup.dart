import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';
import 'package:sqflite_common_ffi/src/windows/setup_impl.dart';
import 'package:sqflite_common_ffi/src/windows/sqlite3_info.dart';

class Sqlite3DllSetupHelper {
  final Sqlite3DllInfo sqlite3Info;
  // This tests does actually the actual install of the dll

  late var srcZip = sqlite3Info.srcZip;
  late var localZip = join('.local', basename(srcZip));
  late var localExtractedZipDir = join(
    '.local',
    basenameWithoutExtension(srcZip),
  );
  late var localExtractedJsonInfoFile = join(
    localExtractedZipDir,
    sqflite3InfoJsonFileName,
  );
  var bundledDir = join('lib', dirname(packageGetSqlite3DllPath('.')));
  late var bundledJsonInfoFilePath = join(bundledDir, 'sqlite3_info.json');
  late var bundledSqlite3DllFilePath = join(bundledDir, 'sqlite3.dll');
  late var localInfoZip = join('.local', basename(srcZip));

  Sqlite3DllSetupHelper(this.sqlite3Info);

  /// For tools and test only. not exported.
  /// Returns null on failure, don't care about the failure...
  Future<Sqlite3DllInfo?> readBundleInfo() async {
    try {
      var map = pathGetJson(bundledJsonInfoFilePath);
      var sqlite3Info = Sqlite3DllInfo.fromMap(map);
      // ignore: avoid_print
      stdout.writeln('sqlite3Info $sqlite3Info');
    } catch (_) {}
    return null;
  }

  Future<bool> getZip() async {
    if (!File(localZip).existsSync()) {
      stdout.writeln('Downloading sqlite3 $sqlite3Info');
      await Directory(dirname(localZip)).create(recursive: true);
      try {
        await File(localZip).writeAsBytes(await readBytes(Uri.parse(srcZip)));
      } catch (e) {
        stderr.writeln(
          'Fail to fetch sqlite.zip version $sqlite3_38_2Info at $srcZip',
        );
        return false;
      }
    }
    return true;
  }

  Future<void> extractZip() async {
    var jsonInfo = File(localExtractedJsonInfoFile);
    if (!jsonInfo.existsSync()) {
      // Extract the zip
      stdout.writeln('Extracting $localZip to $localExtractedZipDir');
      final inputStream = InputFileStream(localZip);
      final archive = ZipDecoder().decodeStream(inputStream);
      await extractArchiveToDisk(archive, localExtractedZipDir);
      await jsonInfo.writeAsString(jsonEncode(sqlite3Info.toMap()));
    }
  }

  Future<void> copyToBundle() async {
    var srcFile = join(localExtractedZipDir, 'sqlite3.dll');
    var dstFile = bundledSqlite3DllFilePath;
    stdout.writeln('Copying $srcZip to $dstFile');
    //await File(dstFile).delete(recursive: true);
    await File(srcFile).copy(dstFile);
    await File(
      bundledJsonInfoFilePath,
    ).writeAsString(jsonEncode(sqlite3Info.toMap()));
    //await File()
  }
}

/// This tool is actually ran on linux to download install the updated dll
Future main() async {
  await setupSqliteDll();
}

Future setupSqliteDll() async {
  // Tested only on linux for now.
  if (Platform.isLinux) {
    var helper = Sqlite3DllSetupHelper(sqlite3Info);
    var info = await helper.readBundleInfo();
    if (info?.version != sqlite3Info.version) {
      await helper.getZip();
      await helper.extractZip();
      await helper.copyToBundle();
    } else {
      stdout.writeln('sqlite3 $sqlite3Info already up to date');
    }
  } else {
    stderr.writeln('To run on linux!');
  }
}
