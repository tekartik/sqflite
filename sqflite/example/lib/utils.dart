export 'dart:io' hide sleep;

/// Usage: await sleep(500);
Future sleep([int milliseconds]) =>
    Future.delayed(Duration(milliseconds: milliseconds));
