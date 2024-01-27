#if os(iOS)
  import Flutter
  import UIKit
#elseif os(macOS)
  import FlutterMacOS
  import Cocoa
#endif


public class SqfliteDarwinPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
#if os(iOS)
    let channel = FlutterMethodChannel(name: "sqflite_darwin", binaryMessenger: registrar.messenger());
#elseif os (macOS)
    let channel = FlutterMethodChannel(name: "sqflite_darwin", binaryMessenger: registrar.messenger);
#endif
    let instance = SqfliteDarwinPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
  #if os(iOS)
      result("iOS " + UIDevice.current.systemVersion)
  #elseif os (macOS)
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
  #endif
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
