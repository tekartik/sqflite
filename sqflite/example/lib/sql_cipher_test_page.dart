import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/test_page.dart';

///encrypt test page
class SQLCipherTestPage extends TestPage {
  ///encrypt test page
  SQLCipherTestPage({super.key}) : super('sqlcipher test page') {
    test('encrypt database', () async {
      await deleteDatabase('test.db');
      var tempDb = await openDatabase('test.db', password: '');

      await tempDb.execute('CREATE TABLE students (id INTEGER PRIMARY KEY, name TEXT)');

      expect(await tempDb.insert('students', {
        'id': 1,
        'name': 'Nguyen Van A',
      }), 1);

      expect(await tempDb.insert('students', {
        'id': 2,
        'name': 'Nguyen Van B',
      }), 2);

      expect ((await tempDb.query('students')).length, 2);

      await tempDb.close();

      expect(await encryptDatabase('${await getDatabasesPath()}/test.db', '#123@'), true);
    });

    test('re-open after encryption', () async {
      try {
        //must throw an error here
        await openDatabase('test.db', password: '');
        expect(0, 1);
      } catch (e) {
        //
      }

      var encryptedDb = await openDatabase('test.db', password: '#123@');

      expect ((await encryptedDb.query('students')).length, 2);
      await encryptedDb.close();
    });

    test('change password', () async {
      var encryptedDb = await openDatabase('test.db', password: '#123@');

      expect ((await encryptedDb.changePassword('123')), true);
      await encryptedDb.close();

      encryptedDb = await openDatabase('test.db', password: '123');

      expect ((await encryptedDb.query('students')).length, 2);
      await encryptedDb.close();
    });

    test('decrypt database', () async {
      await deleteDatabase('test.db');
      var tempDb = await openDatabase('test.db', password: '#123@');

      await tempDb.execute('CREATE TABLE students (id INTEGER PRIMARY KEY, name TEXT)');

      expect(await tempDb.insert('students', {
        'id': 1,
        'name': 'Nguyen Van A',
      }), 1);

      expect(await tempDb.insert('students', {
        'id': 2,
        'name': 'Nguyen Van B',
      }), 2);

      expect ((await tempDb.query('students')).length, 2);

      await tempDb.close();

      expect(await decryptDatabase('${await getDatabasesPath()}/test.db', '#123@'), true);
    });

    test('re-open after decryption', () async {
      try {
        //must throw an error here
        await openDatabase('test.db', password: '#123@');
        expect(0, 1);
      } catch (e) {
        //
      }

      var decryptedDb = await openDatabase('test.db', password: '');

      expect ((await decryptedDb.query('students')).length, 2);
      await decryptedDb.close();
    });
  }

}
