export 'dart:io' hide sleep;

/// Usage: await sleep(500);
Future sleep([int milliseconds = 0]) =>
    Future.delayed(Duration(milliseconds: milliseconds));
