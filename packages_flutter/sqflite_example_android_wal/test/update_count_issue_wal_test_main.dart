// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test from issues #1204 (wal mode on android), thanks to absar
/// To run using
/// flutter run -t test/update_count_issue_wal_test_main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  test('Updating existing row should return 1 in WAL mode', () async {
    final book = await bookRepository.getBook(BookRepository.book1Id);
    expect(book, isNotNull);
    // Change description to confirm data is updated
    book!['description'] = 'If you can see me i am updated in the DB';
    await bookRepository.saveBook(book);
  });

  test('Deleting existing row should return 1 in WAL mode', () async {
    final book = await bookRepository.getBook(BookRepository.book2Id);
    expect(book, isNotNull);
    final count = await bookRepository.deleteBook(book!['id']);
    expect(count, 1, reason: 'Deleting existing row should return 1');
  });
}

class LocalDatabaseService {
  static LocalDatabaseService? _instance;
  static Database? _database;

  Database? get database => _database;

  static Future<LocalDatabaseService> instance() async {
    if (_instance != null) return _instance!;
    final dbPath = join(await getDatabasesPath(), 'my_db.db');
    await deleteDatabase(dbPath);
    _instance = LocalDatabaseService._internal();
    _database = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        // The issue is still there even if we enable it here as well for Android instead of just in AndroidManifest
        if (Platform.isIOS) {
          await db.setJournalMode('WAL');
        }
      },
      onCreate: (db, version) async {
        final batch = db.batch();
        _createTables(batch);
        await batch.commit(noResult: true);
      },
    );
    return _instance!;
  }

  LocalDatabaseService._internal();
}

const booksTableName = 'books';

void _createTables(Batch batch) {
  batch.execute('DROP TABLE IF EXISTS $booksTableName');
  batch.execute('''CREATE TABLE $booksTableName (
  "id" INTEGER PRIMARY KEY,
  "description" TEXT
)''');

  _insertDummyData(batch);
}

void _insertDummyData(Batch batch) {
  final trx = bookRepository.getAllSampleBooks();
  for (final tr in trx) {
    batch.insert(booksTableName, tr);
  }
}

final bookRepository = BookRepository.instance();

class BookRepository {
  static BookRepository? _instance;

  static BookRepository instance() {
    if (_instance != null) return _instance!;
    _instance = BookRepository._internal();
    return _instance!;
  }

  static final int book1Id = 1;
  static final int book2Id = 2;

  BookRepository._internal() {
    _books[book1Id] = <String, dynamic>{
      'id': book1Id,
      'description': 'Test desc 1',
    };
    _books[book2Id] = <String, dynamic>{
      'id': book2Id,
      'description': 'Test desc 2',
    };
  }

  final _books = HashMap<int, Map<String, dynamic>>();

  List<Map<String, dynamic>> getAllSampleBooks() {
    return _books.values.toList();
  }

  Future<Map<String, dynamic>?> getBook(int id) async {
    final db = (await LocalDatabaseService.instance()).database!;
    final savedData = await db.query(
      booksTableName,
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
    var result = savedData.firstOrNull;
    return result != null ? Map.from(result) : null;
  }

  Future<void> saveBook(Map<String, dynamic> book) async {
    final db = (await LocalDatabaseService.instance()).database!;
    var savedData = await getBook(book['id']);
    print(
      'To confirm the id and row already exists, queried from DB: $savedData',
    );

    // Update should return the number of rows updated but in WAL mode it returns 0 on Android
    final count = await db.update(
      booksTableName,
      book,
      where: 'id = ?',
      whereArgs: <dynamic>[book['id']],
    );

    savedData = await getBook(book['id']);
    print('Rows updated: $count. But data is actually saved: $savedData');
    if (count == 0) {
      print(
        'It says zero rows updated, but in reality 1 row is updated but count always returns 0. '
        'Furthermore insert will also fail since the row with the given ID already exists',
      );
      await db.insert(booksTableName, book);
    } else {
      print('Records updated $count');
    }
  }

  Future<int> deleteBook(int id) async {
    final db = (await LocalDatabaseService.instance()).database!;
    var savedData = await getBook(id);
    print(
      'To confirm the id and row already exists, queried from DB: $savedData',
    );

    // Delete should return the number of rows deleted but in WAL mode it returns 0 on Android
    final count = await db.delete(
      booksTableName,
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
    savedData = await getBook(id);
    print('Rows deleted: $count. But record is actually deleted: $savedData');
    return count;
  }
}
