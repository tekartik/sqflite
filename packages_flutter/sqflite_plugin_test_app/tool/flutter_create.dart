import 'package:sqflite_support/flutter_device.dart';

/// The platform folders are generated (and git ignored): Android, iOS and
/// macOS, the platforms of the sqflite plugin.
Future<void> main() async {
  await flutterCreate();
}

/// Creates the platform folders when missing.
Future<void> flutterCreate() async {
  await flutterCreatePlatforms(['android', 'ios', 'macos']);
}
