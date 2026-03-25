# sqflite_common_ffi_async vs sqflite_common_ffi

`slow_test.dart` result: 
2026-03-25: Tested on a i9 12900K 64GB RAM Ubuntu 24.04
```txt
sqflite_common_ffi_async:
100 insert: 0:00:00.038807
100 insert no txn: 0:00:00.234575
1000 insert 0:00:00.095465
1000 insert batch 0:00:00.065962
1000 insert batch no result 0:00:00.051374

sqflite_common_ffi (no wal):
100 insert: 0:00:00.029640
100 insert no txn: 0:00:20.513319
1000 insert 0:00:00.120250
1000 insert batch 0:00:00.030864
1000 insert batch no result 0:00:00.038577
```