import 'dart:io';

import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// Statement test.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;

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
      skip: context.strict && !Platform.isWindows);
}
