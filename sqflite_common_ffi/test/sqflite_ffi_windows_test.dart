@TestOn('vm')
import 'dart:io';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';
import 'package:test/test.dart';

var version = '3.38.1';
var src = 'https://www.sqlite.org/2022/sqlite-dll-win64-x64-3380100.zip';

Future<String> computeSha3(String file) async {
  var line = (await run('openssl dgst -sha3-256 ${shellArgument(file)}'))
      .outLines
      .last;
  // SHA3-256(.local/sqlite-dll-win64-x64-3380100.zip)= 0e014495eb829bc41ce48783b7a7db362f9cfd61c40a624683aba7868b712c4b
  var sha3 = line.trim().split(' ').last;
  return sha3;
}

void main() {
  group('sqlite3.dll', () {
    test('sha3', () async {
      var dllPath = findWindowsDllPath();
      if (dllPath != null) {
        if (Platform.isLinux) {
          if ((await which('openssl')) != null) {
            await run('openssl dgst -sha3-512 ${shellArgument(dllPath)}');
            // Local test
            //var localDll = join('.local', 'sqlite3.dll');
            var localZip = join('.local', basename(src));
            if (!File(localZip).existsSync()) {
              try {
                await File(localZip)
                    .writeAsBytes(await readBytes(Uri.parse(src)));
              } catch (e) {
                stderr.writeln(
                    'Fail to fetch sqlite.zip version $version at $src');
                return;
              }
            }
            // sqlite-dll-win64-x64-3380100.zip
            // (895.98 KiB)		64-bit DLL (x64) for SQLite version 3.38.1.
            // (sha3: 0e014495eb829bc41ce48783b7a7db362f9cfd61c40a624683aba7868b712c4b)
            //await run('openssl dgst -sha3-512 ${shellArgument(localDll)}');
            // await run('openssl dgst -sha3-256 ${shellArgument(localZip)}');
            print(await computeSha3(localZip));
          }
        }
      }
    });
  });
}
