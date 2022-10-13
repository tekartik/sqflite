import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import 'src/core_import.dart';

/// Statement test.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;

  group('statement', () {
    test('with_sudoku_solver', () async {
      //await Sqflite.setDebugModeOn(true);
      var path = await context.initDeleteDb('with_sudoku_solver.db');
      var db = await factory.openDatabase(path);
      try {
        var result = await db.rawQuery('''
WITH RECURSIVE
  input(sud) AS (
    VALUES('53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79')
  ),
  digits(z, lp) AS (
    VALUES('1', 1)
    UNION ALL SELECT
    CAST(lp+1 AS TEXT), lp+1 FROM digits WHERE lp<9
  ),
  x(s, ind) AS (
    SELECT sud, instr(sud, '.') FROM input
    UNION ALL
    SELECT
      substr(s, 1, ind-1) || z || substr(s, ind+1),
      instr( substr(s, 1, ind-1) || z || substr(s, ind+1), '.' )
     FROM x, digits AS z
    WHERE ind>0
      AND NOT EXISTS (
            SELECT 1
              FROM digits AS lp
             WHERE z.z = substr(s, ((ind-1)/9)*9 + lp, 1)
                OR z.z = substr(s, ((ind-1)%9) + (lp-1)*9 + 1, 1)
                OR z.z = substr(s, (((ind-1)/3) % 3) * 3
                        + ((ind-1)/27) * 27 + lp
                        + ((lp-1) / 3) * 6, 1)
         )
  )
SELECT s FROM x WHERE ind=0;
            ''');
        //print(result);
        expect(result, [
          {
            's':
                '534678912672195348198342567859761423426853791713924856961537284287419635345286179'
          }
        ]);
      } finally {
        await db.close();
      }
    },
        // This fail on ubuntu...why
        skip: context.strict && !platform.isWindows);

    test('indexed_param', () async {
      final db = await factory.openDatabase(inMemoryDatabasePath);
      expect(await db.rawQuery('SELECT ?1 + ?2', [3, 4]), [
        {'?1 + ?2': 7}
      ]);
      try {
        expect(await db.rawQuery('SELECT ? as a', [2]), [
          {'a': 2}
        ]);
      } catch (e) {
        print('failed on Android $e');
        expect(await db.rawQuery('SELECT ? as a', [2]), [
          {'a': '2'}
        ]);
      }
      try {
        expect(await db.rawQuery('SELECT ? as a', [1.5]), [
          {'a': 1.5}
        ]);
      } catch (e) {
        print('failed on Android $e');
        expect(await db.rawQuery('SELECT ?1 as a', [1.5]), [
          {'a': '1.5'}
        ]);
      }
      try {
        expect(await db.rawQuery('SELECT ?1 as a', [1.5]), [
          {'a': 1.5}
        ]);
      } catch (e) {
        print('failed on Android $e');
        expect(await db.rawQuery('SELECT ?1 as a', [1.5]), [
          {'a': '1.5'}
        ]);
      }
      expect(
          await db.rawQuery(
              'SELECT ?1 + 0 as item1, ?2 + 0 as item2, ?1 + ?2 as sum',
              [3, 4]),
          [
            {'item1': 3, 'item2': 4, 'sum': 7}
          ]);
      await db.close();
    });

    test('Weird column name', () async {
      final db = await factory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE Test ("COUNT(*)" INTEGER)');

      var map = {'COUNT(*)': 1};
      await db.insert(
          'Test', map.map((key, value) => MapEntry('"$key"', value)));

      await db.execute('CREATE TABLE Test2 (\'""\' INTEGER)');
      await db.close();
    });
  });
}
