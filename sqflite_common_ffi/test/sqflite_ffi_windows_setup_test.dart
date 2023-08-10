@TestOn('vm')
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';
import 'package:sqflite_common_ffi/src/windows/sqlite3_info.dart';
import 'package:test/test.dart';

import '../tool/windows_setup.dart';

Future<String> computeSha3(String file, {String openssl = 'openssl'}) async {
  var line = (await run(
          '${shellArgument(openssl)} dgst -sha3-256 ${shellArgument(file)}'))
      .outLines
      .last;
  // SHA3-256(.local/sqlite-dll-win64-x64-3380100.zip)= 0e014495eb829bc41ce48783b7a7db362f9cfd61c40a624683aba7868b712c4b
  var sha3 = line.trim().split(' ').last;
  return sha3;
}

String? _openSsl;

Future<String?> windowsFindOpenssl() async {
  return _openSsl ??= await () async {
    var found = await which('openssl');
    if (found == null) {
      // Sometimes it is here:
      // "C:\Program Files\Git\usr\bin\openssl.exe"
      // if git is here: C:\Program Files\Git\cmd\git.exe
      var gitFound = await which('git');
      if (gitFound != null) {
        var tryNext = join(dirname(dirname(gitFound)), 'usr', 'bin');
        var env = ShellEnvironment()..paths.add(tryNext);
        found = await which('openssl', environment: env);
      }
    }
    return found;
  }();
}

void main() {
  var helper = Sqlite3DllSetupHelper(sqlite3Info);
  var srcZip = sqlite3Info.srcZip;
  var localZip = join('.local', basename(srcZip));

  group('sqlite3.dll', () {
    test('sha3', () async {
      String? openssl;
      openssl = await which('openssl');
      if (openssl == null && Platform.isWindows) {
        openssl = await windowsFindOpenssl();
      }
      if (openssl != null) {
        if (await helper.getZip()) {
          var computed = await computeSha3(localZip, openssl: openssl);
          expect(computed, sqlite3Info.sha3);
        }
      }
    });

    test('checkDll', () async {
      var dllPath = findWindowsDllPath()!;
      if (await helper.getZip()) {
        final inputStream = InputFileStream(localZip);
        final archive = ZipDecoder().decodeBuffer(inputStream);
        extractArchiveToDisk(archive, dirname(localZip));

        var downloadedDllContent =
            await File(join(dirname(localZip), 'sqlite3.dll')).readAsBytes();
        var existingDllContent = await File(dllPath).readAsBytes();
        expect(existingDllContent, downloadedDllContent);
      }
    });
  });
}
