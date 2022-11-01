import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

import 'batch_test.dart' as batch_test;
import 'database_factory_test.dart' as database_factory_test;
import 'doc_test.dart' as doc_test;
import 'exception_test.dart' as exception_test;
import 'exp_test.dart' as exp_test;
import 'issue_test.dart' as issue_test;
import 'open_flutter_test.dart' as open_flutter_test;
import 'open_test.dart' as open_test;
import 'raw_test.dart' as raw_test;
import 'service_impl_test.dart' as log_test;
import 'service_impl_test.dart' as service_impl_test;
import 'slow_test.dart' as slow_test;
import 'sqflite_protocol_test.dart' as protocol_test;
import 'statement_test.dart' as statement_test;
import 'transaction_test.dart' as transaction_test;
import 'type_test.dart' as type_test;

/// Run all common tests.
void run(SqfliteTestContext context) {
  group('all', () {
    protocol_test.run(context);
    service_impl_test.run(context);
    batch_test.run(context);
    log_test.run(context);
    doc_test.run(context);
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
  });
}
