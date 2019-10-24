import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/factory_mixin.dart' as impl;
import 'package:sqflite/utils/utils.dart';
import 'package:sqflite_example/model/item.dart';
import 'package:sqflite_example/src/item_widget.dart';
import 'package:sqflite_example/utils.dart';

/// Manual test page.
class ManualTestPage extends StatefulWidget {
  @override
  _ManualTestPageState createState() => _ManualTestPageState();
}

class _ManualTestPageState extends State<ManualTestPage> {
  Database database;

  Future<Database> _openDatabase() async {
    return database ??= await databaseFactory.openDatabase('manual_test.db');
  }

  Future _closeDatabase() async {
    await database?.close();
    database = null;
  }

  List<MenuItem> items;
  List<ItemWidget> itemWidgets;

  Future<bool> pop() async {
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    items = <MenuItem>[
      MenuItem('openDatabase', () async {
        await _openDatabase();
      }, summary: 'Open the database'),
      MenuItem('BEGIN EXCLUSIVE', () async {
        var db = await _openDatabase();
        await db.execute('BEGIN EXCLUSIVE');
      },
          summary:
              'Execute than exit or hot-restart the application. Open the database if needed'),
      MenuItem('close', () async {
        await _closeDatabase();
      },
          summary:
              'Execute after starting then exit the app using the back button on Android and restart from the launcher.'),
      MenuItem('log level: none', () async {
        // ignore: deprecated_member_use
        await Sqflite.devSetOptions(
            // ignore: deprecated_member_use
            SqfliteOptions(logLevel: sqfliteLogLevelNone));
      }, summary: 'No logs'),
      MenuItem('log level: sql', () async {
        // ignore: deprecated_member_use
        await Sqflite.devSetOptions(
            // ignore: deprecated_member_use
            SqfliteOptions(logLevel: sqfliteLogLevelSql));
      }, summary: 'Log sql command and basic database operation'),
      MenuItem('log level: verbose', () async {
        // ignore: deprecated_member_use
        await Sqflite.devSetOptions(
            // ignore: deprecated_member_use
            SqfliteOptions(logLevel: sqfliteLogLevelVerbose));
      }, summary: 'Verbose logs, for debugging'),
      MenuItem('Get info', () async {
        final factory = databaseFactory as impl.SqfliteDatabaseFactoryMixin;
        var info = await factory.getDebugInfo();
        print(info?.toString());
      }, summary: 'Implementation info (dev only)'),
      MenuItem('Multiple db', () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) {
          return MultipleDbTestPage();
        }));
      }, summary: 'Open multiple databases')
    ];
  }

  @override
  Widget build(BuildContext context) {
    itemWidgets = items
        .map((item) => ItemWidget(
              item,
              (item) async {
                final stopwatch = Stopwatch()..start();
                var future = item.run();
                setState(() {});
                await future;
                // always add a small delay
                var elapsed = stopwatch.elapsedMilliseconds;
                if (elapsed < 300) {
                  await sleep(300 - elapsed);
                }
                setState(() {});
              },
              summary: item.summary,
            ))
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Manual tests'),
      ),
      body: WillPopScope(
          child: ListView(
            children: itemWidgets,
          ),
          onWillPop: pop),
    );
  }
}

/// Multiple db test page.
class MultipleDbTestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget dbTile(String name) {
      return ListTile(
        title: Text(name),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) {
            return SimpleDbTestPage(
              dbName: name,
            );
          }));
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Multiple databases'),
      ),
      body: ListView(
        children: <Widget>[
          dbTile('data1.db'),
          dbTile('data2.db'),
          dbTile('data3.db')
        ],
      ),
    );
  }
}

/// Simple db test page.
class SimpleDbTestPage extends StatefulWidget {
  /// Simple db test page.
  const SimpleDbTestPage({Key key, this.dbName}) : super(key: key);

  /// db name.
  final String dbName;

  @override
  _SimpleDbTestPageState createState() => _SimpleDbTestPageState();
}

class _SimpleDbTestPageState extends State<SimpleDbTestPage> {
  Database database;

  Future<Database> _openDatabase() async {
    // await Sqflite.devSetOptions(SqfliteOptions(logLevel: sqfliteLogLevelVerbose));
    return database ??= await databaseFactory.openDatabase(widget.dbName,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE Test (value TEXT)');
            }));
  }

  Future _closeDatabase() async {
    await database?.close();
    database = null;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Simple db ${widget.dbName}'),
        ),
        body: Builder(
          builder: (context) {
            Widget menuItem(String title, void Function() onTap,
                {String summary}) {
              return ListTile(
                title: Text(title),
                subtitle: summary == null ? null : Text(summary),
                onTap: onTap,
              );
            }

            Future _countRecord() async {
              var db = await _openDatabase();
              var result = await firstIntValue(
                  await db.query('test', columns: ['COUNT(*)']));
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text('$result records'),
                duration: Duration(milliseconds: 700),
              ));
            }

            var items = <Widget>[
              menuItem('open Database', () async {
                await _openDatabase();
              }, summary: 'Open the database'),
              menuItem('Add record', () async {
                var db = await _openDatabase();
                await db.insert('test', {'value': 'some_value'});
                await _countRecord();
              }, summary: 'Add one record. Open the database if needed'),
              menuItem('Count record', () async {
                await _countRecord();
              }, summary: 'Count records. Open the database if needed'),
              menuItem(
                'Close Database',
                () async {
                  await _closeDatabase();
                },
              ),
            ];
            return ListView(
              children: items,
            );
          },
        ));
  }
}
