import 'package:flutter/src/services/platform_channel.dart';

const String channelName = 'com.tekartik.sqflite';

const MethodChannel channel = const MethodChannel(channelName);

// Temp flag to test concurrent reads
final bool supportsConcurrency = false;
