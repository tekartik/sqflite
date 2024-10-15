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

#### Solution for github actions

The issue above might happen when running ubuntu-latest on github actions (since `Ubuntu 24.04.1 LTS`, fine up to `ubuntu-22.04.5`).

You can add the following run step (that works on all platforms as it only performs the install for linux):

```
      ...
      # Setup sqlite3 lib (done for linux only but works safely on all platform)
      - name: Install libsqlite3-dev
        run: |
          dart pub global activate --source git https://github.com/tekartik/ci.dart --git-path ci
          dart pub global run tekartik_ci:setup_sqlite3lib
      ...
```

Or if you know that you are on linux you can simply add:
```
     - run: sudo apt-get -y install libsqlite3-dev
```