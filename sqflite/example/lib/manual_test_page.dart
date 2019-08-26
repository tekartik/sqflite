import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/factory_mixin.dart' as impl;
import 'package:sqflite_example/model/item.dart';
import 'package:sqflite_example/src/item_widget.dart';
import 'package:sqflite_example/utils.dart';

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
      }, summary: 'Implementation info (dev only)')
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
