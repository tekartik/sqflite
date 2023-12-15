// ignore_for_file: unused_import

import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

import 'package:sqflite_common_test/batch_test.dart' as batch_test;
import 'package:sqflite_common_test/database_factory_test.dart'
    as database_factory_test;
import 'package:sqflite_common_test/doc_test.dart' as doc_test;
import 'package:sqflite_common_test/exception_test.dart' as exception_test;
import 'package:sqflite_common_test/exp_test.dart' as exp_test;
import 'package:sqflite_common_test/issue_test.dart' as issue_test;
import 'package:sqflite_common_test/open_flutter_test.dart'
    as open_flutter_test;
import 'package:sqflite_common_test/open_test.dart' as open_test;
import 'package:sqflite_common_test/raw_test.dart' as raw_test;
import 'package:sqflite_common_test/service_impl_test.dart' as log_test;
import 'package:sqflite_common_test/service_impl_test.dart'
    as service_impl_test;
import 'package:sqflite_common_test/slow_test.dart' as slow_test;
import 'package:sqflite_common_test/sqflite_protocol_test.dart'
    as protocol_test;
import 'package:sqflite_common_test/statement_test.dart' as statement_test;
import 'package:sqflite_common_test/transaction_test.dart' as transaction_test;
import 'package:sqflite_common_test/type_test.dart' as type_test;
import 'package:sqflite_common_test/wal_test.dart';

/// Run all common tests.
void runFfiAsyncTests(SqfliteTestContext context) {
  group('all', () {
    // ignore: dead_code
    if (false) {
      protocol_test.run(context);
      service_impl_test.run(context);
      batch_test.run(context);
      log_test.run(context);

      open_flutter_test.run(context);
      slow_test.run(context);
      type_test.run(context);
      statement_test.run(context);
      raw_test.run(context);
      open_test.run(context);
      exception_test.run(context);
      exp_test.run(context);
      database_factory_test.run(context);
      transaction_test.run(context);
      issue_test.run(context);
      walTests(context);
    } else {
      if (true) {
        doc_test.run(context);
        service_impl_test.run(context);
        batch_test.run(context);
        log_test.run(context);

        open_flutter_test.run(context);
        slow_test.run(context);
        type_test.run(context);
        statement_test.run(context);
        raw_test.run(context);
        open_test.run(context);
        exception_test.run(context);
        exp_test.run(context);
        database_factory_test.run(context);
        transaction_test.run(context);
        issue_test.run(context);
        walTests(context);
        // ignore: dead_code
      } else {
        batch_test.run(context);
        open_test.run(context);
        raw_test.run(context);
      }
    }
  });
}
