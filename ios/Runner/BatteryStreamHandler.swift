import Flutter
import UIKit

/// A FlutterStreamHandler that streams battery status changes to the client.
class BatteryStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // Enable battery monitoring to observe state changes
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Register notifications for battery level and state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryChanged),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        
        // Send initial battery state immediately on subscription
        sendBatteryUpdate()
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // Clean up observer resources and disable battery monitoring
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.isBatteryMonitoringEnabled = false
        self.eventSink = nil
        return nil
    }
    
    @objc private func batteryChanged() {
        sendBatteryUpdate()
    }
    
    private func sendBatteryUpdate() {
        guard let sink = eventSink else { return }
        
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        
        // Map native battery state enum to simple boolean charging indicator
        let isCharging = state == .charging || state == .full
        
        // UIDevice batteryLevel returns -1 if monitoring is disabled or unavailable (like on Simulator)
        let normalizedLevel = level < 0 ? 0.0 : Double(level)
        
        let payload: [String: Any] = [
            "level": normalizedLevel,
            "isCharging": isCharging
        ]
        sink(payload)
    }
}
