## Linux

### Missing `libsqlite3.so`

if you get

```
 SqfliteFfiException(error, Invalid argument(s): Failed to load dynamic library (libsqlite3.so: cannot open shared object file: No such file or directory)}
```

Make sure to install the linux package `sqlite3-dev`. 

```$xslt
sudo apt-get -y install libsqlite3-dev
```