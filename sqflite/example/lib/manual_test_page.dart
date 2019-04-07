import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
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
  void initState() {
    items = <MenuItem>[
      MenuItem('BEGIN EXCLUSIVE', () async {
        // await Sqflite.devSetDebugModeOn(true);
        var db = await _openDatabase();
        await db.execute('BEGIN EXCLUSIVE');
      },
          summary:
              'Execute than exit or hot-restart the application. Open the database if needed'),
      MenuItem('close', () async {
        await _closeDatabase();
      },
          summary:
              'Execute after starting then exit the app using the back button on Android and restart from the launcher.')
    ];
    super.initState();
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
