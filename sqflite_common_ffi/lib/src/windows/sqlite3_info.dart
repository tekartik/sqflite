/// Information about the bundled sqlite3.dll
/// https://www.sqlite.org/download.html
class Sqlite3DllInfo {
  /// Version string.
  final String version;

  /// Src zip.
  final String srcZip;

  /// Sha3.
  final String sha3;

  /// Sqflite3DllInfo.
  Sqlite3DllInfo(this.version, this.srcZip, this.sha3);

  /// Sqflite3DllInfo from map.
  factory Sqlite3DllInfo.fromMap(Map map) => Sqlite3DllInfo(
    map['version']!.toString(),
    map['srcZip']!.toString(),
    map['sha3']!.toString(),
  );

  /// To map.
  Map<String, Object?> toMap() => <String, Object?>{
    'version': version,
    'srcZip': srcZip,
    'sha3': sha3,
  };
  @override
  String toString() => '$version $srcZip $sha3';
}

/// 3.38.2 info
var sqlite3_38_2Info = Sqlite3DllInfo(
  '3.38.2',
  'https://www.sqlite.org/2022/sqlite-dll-win64-x64-3380200.zip',
  '9f71eec9a2c7f12602eaa2af76bd7c052e540502ae7a89dac540e10962e2fa35',
);

// sqlite-dll-win64-x64-3420000.zip
// (1.16 MiB)		64-bit DLL (x64) for SQLite version 3.42.0.
// (SHA3-256: 2425efa95556793a20761dfdab0d3b56a52e61716e8bb65e6a0a3590d41c97c0)
/// 3.42.0 info
var sqlite3_42_0Info = Sqlite3DllInfo(
  '3.42.0',
  'https://www.sqlite.org/2023/sqlite-dll-win64-x64-3420000.zip',
  '2425efa95556793a20761dfdab0d3b56a52e61716e8bb65e6a0a3590d41c97c0',
);

// sqlite-dll-win-x64-3500100.zip
// (1.28 MiB)		64-bit DLL (x64) for SQLite version 3.50.1.
// (SHA3-256: 2bf2afb9a6b94dffcc033f37ebdc50118d0ea9e5536729421efa8fb4eb2a5c5f)
/// 3.50.1 info
var sqlite3_50_1Info = Sqlite3DllInfo(
  '3.50.1',
  'https://www.sqlite.org/2025/sqlite-dll-win-x64-3500100.zip',
  '2bf2afb9a6b94dffcc033f37ebdc50118d0ea9e5536729421efa8fb4eb2a5c5f',
);

/// Current info
var sqlite3Info = sqlite3_50_1Info;
