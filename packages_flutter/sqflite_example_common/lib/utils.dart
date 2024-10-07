/// Usage: await sleep(500);
Future sleep([int milliseconds = 0]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

/// Supports compat mode (devSetDebugModeOn, queryAsMap, fts4, some error handled - missing parameter, bad file)
/// Should only be true for the sqflite package.
var supportsCompatMode = false;
