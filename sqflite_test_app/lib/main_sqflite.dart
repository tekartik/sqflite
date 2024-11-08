import 'package:flutter/cupertino.dart';
import 'package:sqflite_example_common/main.dart';
import 'package:sqflite_test_app/page/plugin_test_page.dart';

/// Use regular sqflite, should work on Android, iOS and MacOS
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  extraRoutes = <String, WidgetBuilder>{
    '/test/plugin': (_) => PluginTestPage(),
  };
  mainExampleApp();
}
