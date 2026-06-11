import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

class _FakeDatabaseFactory implements DatabaseFactory {
  /// Recorded paths.
  final paths = <String>[];

  String databasesPath = p.normalize('/databases');

  @override
  Future<bool> databaseExists(String path) async {
    paths.add(path);
    return false;
  }

  @override
  Future<void> deleteDatabase(String path) async {
    paths.add(path);
  }

  @override
  Future<String> getDatabasesPath() async => databasesPath;

  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    paths.add(path);
    throw UnsupportedError('openDatabase not supported in fake factory');
  }

  @override
  Future<Uint8List> readDatabaseBytes(String path) async {
    paths.add(path);
    return Uint8List(0);
  }

  @override
  Future<void> setDatabasesPath(String path) async {
    databasesPath = path;
  }

  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) async {
    paths.add(path);
  }

  @override
  String toString() => 'fake';
}

void main() {
  var root = p.normalize('/sandbox');
  group('database_factory_sandbox', () {
    test('relative path', () async {
      var factory = _FakeDatabaseFactory();
      var sandboxed = factory.sandbox(path: root);
      expect(await sandboxed.getDatabasesPath(), root);
      await sandboxed.deleteDatabase('test.db');
      expect(factory.paths.last, p.join(root, 'test.db'));
      expect(await sandboxed.databaseExists(p.join('sub', 'test.db')), isFalse);
      expect(factory.paths.last, p.join(root, 'sub', 'test.db'));
      await sandboxed.writeDatabaseBytes('test.db', Uint8List(0));
      expect(factory.paths.last, p.join(root, 'test.db'));
      await sandboxed.readDatabaseBytes('test.db');
      expect(factory.paths.last, p.join(root, 'test.db'));
    });

    test('absolute path', () async {
      var factory = _FakeDatabaseFactory();
      var sandboxed = factory.sandbox(path: root);
      // Inside the sandbox, used as is.
      await sandboxed.deleteDatabase(p.join(root, 'test.db'));
      expect(factory.paths.last, p.join(root, 'test.db'));
      // Outside the sandbox, throws.
      await expectLater(
        () => sandboxed.deleteDatabase(p.normalize('/test.db')),
        throwsArgumentError,
      );
      await expectLater(
        () => sandboxed.deleteDatabase(p.join(root, '..', 'test.db')),
        throwsArgumentError,
      );
    });

    test('escape attempt', () async {
      var factory = _FakeDatabaseFactory();
      var sandboxed = factory.sandbox(path: root);
      await expectLater(
        () => sandboxed.deleteDatabase(p.join('..', 'test.db')),
        throwsArgumentError,
      );
      await expectLater(
        () => sandboxed.deleteDatabase('.'),
        throwsArgumentError,
      );
      await expectLater(
        () => sandboxed.deleteDatabase('file:test.db'),
        throwsArgumentError,
      );
    });

    test('in memory', () async {
      var factory = _FakeDatabaseFactory();
      var sandboxed = factory.sandbox(path: root);
      await sandboxed.deleteDatabase(inMemoryDatabasePath);
      expect(factory.paths.last, inMemoryDatabasePath);
    });

    test('default path', () async {
      var factory = _FakeDatabaseFactory();
      var sandboxed = factory.sandbox();
      expect(await sandboxed.getDatabasesPath(), factory.databasesPath);
      await sandboxed.deleteDatabase('test.db');
      expect(factory.paths.last, p.join(factory.databasesPath, 'test.db'));
    });

    test('sandbox of sandbox', () async {
      var factory = _FakeDatabaseFactory();
      var sandboxed = factory.sandbox(path: root).sandbox(path: 'sub');
      expect(await sandboxed.getDatabasesPath(), p.join(root, 'sub'));
      await sandboxed.deleteDatabase('test.db');
      expect(factory.paths.last, p.join(root, 'sub', 'test.db'));
      // Sanitized, only one level of sandboxing.
      expect(sandboxed.toString(), 'sandbox(fake, ${p.join(root, 'sub')})');

      // No path, same root as the parent sandbox.
      sandboxed = factory.sandbox(path: root).sandbox();
      expect(await sandboxed.getDatabasesPath(), root);
      await sandboxed.deleteDatabase('test.db');
      expect(factory.paths.last, p.join(root, 'test.db'));
    });

    test('setDatabasesPath', () async {
      var factory = _FakeDatabaseFactory();
      var sandboxed = factory.sandbox(path: root);
      await sandboxed.setDatabasesPath('sub');
      expect(await sandboxed.getDatabasesPath(), p.join(root, 'sub'));
      await sandboxed.deleteDatabase('test.db');
      expect(factory.paths.last, p.join(root, 'sub', 'test.db'));
      // Setting to the root itself is fine.
      await sandboxed.setDatabasesPath(root);
      expect(await sandboxed.getDatabasesPath(), root);
      // Cannot escape the sandbox root.
      await expectLater(
        () => sandboxed.setDatabasesPath(p.normalize('/databases')),
        throwsArgumentError,
      );
      // The delegate databases path is left untouched.
      expect(await factory.getDatabasesPath(), p.normalize('/databases'));
    });
  });
}
