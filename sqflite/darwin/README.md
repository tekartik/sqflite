# Darwin implementation of sqflite plugin.

Initial implementation was using a subset of FMDB available through Cocoapods. FMDB
cocoapod FMDB version has been stuck at 2.7.5 for a long time and my iOS/MacOS is limited
to propose a proper PR to FMDB and take ownership of the FMDB pod.

As of sqflite 2.3.2-1 (2024/01/27), I made the decision to fork/copy FMDB and use it directly in sqflite assuming [FMDB_LICENSE](FMDB_LICENSE.txt)
MIT license allows it.

Only what is necessary has been copied and renamed to avoid name collision (`FMDB` -> `SqfliteDarwin`).

`flutter clean` and deleting the `Podfile.lock` is required to force the update of the FMDB dependency.

I hope everyone is OK with this decision. I'm open to any suggestion or bug report if I missed something.