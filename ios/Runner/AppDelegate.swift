import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    
    // Register the EventChannel stream handler
    let eventChannel = FlutterEventChannel(
      name: "com.chamelalaboratory.demo.flutter_event_channel/eventChannel",
      binaryMessenger: engineBridge.binaryMessenger
    )
    eventChannel.setStreamHandler(ProgressStreamHandler())

    // Register the battery status EventChannel stream handler
    let batteryChannel = FlutterEventChannel(
      name: "com.chamelalaboratory.demo.flutter_event_channel/batteryChannel",
      binaryMessenger: engineBridge.binaryMessenger
    )
    batteryChannel.setStreamHandler(BatteryStreamHandler())
  }
}
