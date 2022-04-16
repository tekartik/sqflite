@TestOn('vm')
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';
import 'package:test/test.dart';

var windowsSqliteVersion = '3.38.2';
var windowsZipSrc =
    'https://www.sqlite.org/2022/sqlite-dll-win64-x64-3380200.zip';
var windowsZipSha3 =
    '9f71eec9a2c7f12602eaa2af76bd7c052e540502ae7a89dac540e10962e2fa35';

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
  var localZip = join('.local', basename(windowsZipSrc));
  Future<bool> getZip() async {
    if (!File(localZip).existsSync()) {
      await Directory(dirname(localZip)).create(recursive: true);
      try {
        await File(localZip)
            .writeAsBytes(await readBytes(Uri.parse(windowsZipSrc)));
      } catch (e) {
        stderr.writeln(
            'Fail to fetch sqlite.zip version $windowsSqliteVersion at $windowsZipSrc');
        return false;
      }
    }
    return true;
  }

  group('sqlite3.dll', () {
    test('sha3', () async {
      String? openssl;
      openssl = await which('openssl');
      if (openssl == null && Platform.isWindows) {
        openssl = await windowsFindOpenssl();
      }
      if (openssl != null) {
        if (await getZip()) {
          var computed = await computeSha3(localZip, openssl: openssl);
          expect(computed, windowsZipSha3);
        }
      }
    });

    test('checkDll', () async {
      var dllPath = findWindowsDllPath()!;
      if (await getZip()) {
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
