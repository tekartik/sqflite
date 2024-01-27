@TestOn('vm')
import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/src/run_ci.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

var runningOnGithubAction = Platform.environment['GITHUB_ACTION'] != null;

void main() {
  workflow();
}

void workflow({bool noBuild = false}) {
  test('flutter config', () async {
    if (isFlutterSupportedSync) {
      await run('flutter config');
    }
  });
  group('flutter test', () {
    setUpAll(() async {
      await buildInitFlutter();
    });
    final dir = join('.dart_tool', 'sqflite_support', 'raw_flutter_test1',
        'test', 'project');
    var ensureCreated = false;
    var shell = Shell(workingDirectory: dir);
    Future<void> create() async {
      await flutterCreateProject(
        path: dir,
      );
      await shell.run('flutter config');
    }

    Future<void> ensureCreate() async {
      if (!ensureCreated) {
        if (!Directory(dir).existsSync()) {
          await create();
        }
        ensureCreated = true;
      }
    }

    Future<void> iosBuild() async {
      if (buildSupportsIOS) {
        await shell.run('flutter build ios --release --no-codesign');
      }
    }

    Future<void> androidBuild() async {
      if (buildSupportsAndroid) {
        await shell.run('flutter build apk');
      }
    }

    Future<void> runCi() async {
      // Allow failure
      try {
        await packageRunCi(dir);
      } catch (e) {
        stderr.writeln('run_ci error $e');
      }
    }

    test('create', () async {
      await create();
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('run_ci', () async {
      await ensureCreate();
      await runCi();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('build ios', () async {
      await ensureCreate();
      await iosBuild();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('build android', () async {
      await ensureCreate();
      // if (!(runningOnGithubAction && Platform.isMacOS)) { // timeout on MacOS to fix
      await androidBuild();
      // }
      await androidBuild();
    },
        timeout: Timeout(Duration(
            minutes: (Platform.isWindows || Platform.isMacOS) ? 10 : 5)));
    test('add sqflite', () async {
      await ensureCreate();
      if (await pathPubspecAddDependency(dir, 'sqflite')) {
        await iosBuild();
        await androidBuild();
        await runCi();
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
    test('add sqflite', () async {
      await ensureCreate();
      var readDependencyLines =
          await pathPubspecGetDependencyLines(dir, 'sqflite');
      if (readDependencyLines == ['sqflite:']) {
        return;
      }
      if (await pathPubspecAddDependency(dir, 'sqflite')) {
        await shell.run('flutter pub get');
        await runCi();
      }
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('add sqflite relative', () async {
      await ensureCreate();
      var dependencyLines = [
        'path: ${posix.join('..', '..', '..', '..', '..', '..', 'sqflite')}'
      ];

      var readDependencyLines =
          await pathPubspecGetDependencyLines(dir, 'sqflite');
      if (readDependencyLines == dependencyLines) {
        return;
      }
      if (await pathPubspecRemoveDependency(dir, 'sqflite')) {
        await shell.run('flutter pub get');
      }

      if (await pathPubspecAddDependency(dir, 'sqflite',
          dependencyLines: dependencyLines)) {
        await shell.run('flutter pub get');
        await runCi();
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }, skip: !isFlutterSupportedSync);
  // TODO @alex find a better to know the flutter build status

  group(
    'dart test',
    () {
      setUpAll(() async {
        await buildInitDart();
      });
      var dir = join(
          '.dart_tool', 'dev_test', 'sqflite_dart_test1', 'test', 'project');
      var ensureCreated = false;
      Future<void> create() async {
        await dartCreateProject(
          path: dir,
        );
      }

      Future<void> ensureCreate() async {
        if (!ensureCreated) {
          if (!Directory(dir).existsSync()) {
            await create();
          }
          ensureCreated = true;
        }
      }

      Future<void> runCi() async {
        // Don't allow failure
        try {
          await packageRunCi(dir);
        } catch (e) {
          stderr.writeln('run_ci error $e');
          rethrow;
        }
      }

      test('create', () async {
        await create();
      }, timeout: const Timeout(Duration(minutes: 5)));
      test('run_ci', () async {
        await ensureCreate();
        await runCi();
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('add sqflite_common_ffi', () async {
        await ensureCreate();
        if (await pathPubspecAddDependency(dir, 'sqflite_common_ffi')) {
          await runCi();
        }
      }, timeout: const Timeout(Duration(minutes: 10)));
    },
  );
}
