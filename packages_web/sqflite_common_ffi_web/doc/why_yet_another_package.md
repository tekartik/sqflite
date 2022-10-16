# Why yet another package for web support

You might wonder, why this is not part of `sqflite` or `sqflite_common_ffi`. There are several opiniated reasons:
- It works in a non-flutter context, unfortunately the common way to define a plugin interface depends on flutter (although the mechanism used here is similar)
- It avoid having too many dependencies by default. This package adds several dependencies (servicer_worker, process_run,
  dev_test) that you might not want. if you don't build for the web. I'm always puzzled that even if you don't target windows
  having a dependency like `path_provider` fetches the `win32` package that you might never need. More dependencies means more risks.
- Configuration for sqflite can be complex (plugin, ffi, cipher) so it is hard to find one solution for all cases
- It is still experimental, honestly supporting SQLite on top of indexeddb does not look pretty. People ask for it though...
