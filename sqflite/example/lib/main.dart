import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/batch_test_page.dart';
import 'package:sqflite_example/exp_test_page.dart';
import 'package:sqflite_example/deprecated_test_page.dart';
import 'model/main_item.dart';
import 'open_test_page.dart';
import 'package:sqflite_example/exception_test_page.dart';
import 'raw_test_page.dart';
import 'slow_test_page.dart';
import 'src/main_item_widget.dart';
import 'type_test_page.dart';
import 'todo_test_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.

  @override
  _MyAppState createState() => _MyAppState();
}

const String testRawRoute = "/test/simple";
const String testOpenRoute = "/test/open";
const String testSlowRoute = "/test/slow";
const String testTypeRoute = "/test/type";
const String testBatchRoute = "/test/batch";
const String testTodoRoute = "/test/todo";
const String testExceptionRoute = "/test/exception";
const String testExpRoute = "/test/exp";
const String testDeprecatedRoute = "/test/deprecated";

class _MyAppState extends State<MyApp> {
  var routes = <String, WidgetBuilder>{
    '/test': (BuildContext context) => MyHomePage(),
    testRawRoute: (BuildContext context) => RawTestPage(),
    testOpenRoute: (BuildContext context) => OpenTestPage(),
    testSlowRoute: (BuildContext context) => SlowTestPage(),
    testTodoRoute: (BuildContext context) => TodoTestPage(),
    testTypeRoute: (BuildContext context) => TypeTestPage(),
    testBatchRoute: (BuildContext context) => BatchTestPage(),
    testExceptionRoute: (BuildContext context) => ExceptionTestPage(),
    testExpRoute: (BuildContext context) => ExpTestPage(),
    testDeprecatedRoute: (BuildContext context) => DeprecatedTestPage(),
  };
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Sqflite Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see
          // the application has a blue toolbar. Then, without quitting
          // the app, try changing the primarySwatch below to Colors.green
          // and then invoke "hot reload" (press "r" in the console where
          // you ran "flutter run", or press Run > Hot Reload App in IntelliJ).
          // Notice that the counter didn't reset back to zero -- the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Sqflite Demo Home Page'),
        routes: routes);
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key) {
    items.add(
        MainItem("Raw tests", "Raw SQLite operations", route: testRawRoute));
    items.add(MainItem("Open tests", "Open onCreate/onUpgrade/onDowngrade",
        route: testOpenRoute));
    items.add(MainItem("Type tests", "Test value types", route: testTypeRoute));
    items.add(MainItem("Batch tests", "Test batch operations",
        route: testBatchRoute));
    items.add(
        MainItem("Slow tests", "Lengthy operations", route: testSlowRoute));
    items.add(MainItem(
        "Todo database example", "Simple Todo-like database usage example",
        route: testTodoRoute));
    items.add(MainItem("Exp tests", "Experimental and various tests",
        route: testExpRoute));
    items.add(MainItem("Exception tests", "Tests that trigger exceptions",
        route: testExceptionRoute));
    items.add(MainItem("Deprecated test",
        "Keeping some old tests for deprecated functionalities",
        route: testDeprecatedRoute));

    // Uncomment to view all logs
    //Sqflite.devSetDebugModeOn(true);
  }

  final List<MainItem> items = [];
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _platformVersion = 'Unknown';

  int get _itemCount => widget.items.length;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Sqflite.platformVersion;
    } on PlatformException {
      platformVersion = "Failed to get platform version";
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    print("running on: " + _platformVersion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title:
              Center(child: Text('Sqflite demo', textAlign: TextAlign.center)),
        ),
        body:
            ListView.builder(itemBuilder: _itemBuilder, itemCount: _itemCount));
  }

  //new Center(child: new Text('Running on: $_platformVersion\n')),

  Widget _itemBuilder(BuildContext context, int index) {
    return MainItemWidget(widget.items[index], (MainItem item) {
      Navigator.of(context).pushNamed(item.route);
    });
  }
}
