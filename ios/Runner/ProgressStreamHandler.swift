import Flutter
import UIKit

/// A FlutterStreamHandler that streams progress events to the client.
class ProgressStreamHandler: NSObject, FlutterStreamHandler {
    private var timer: Timer?
    private var count = 1
    
    // Configuration properties with default values
    private var updateIntervalMs = 200.0
    private var totalCount = 100
    private var shouldSimulateError = false
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        self.count = 1
        
        // Reset defaults
        self.updateIntervalMs = 200.0
        self.totalCount = 100
        self.shouldSimulateError = false
        
        // Parse arguments map from Flutter
        if let args = arguments as? [String: Any] {
            if let shouldSimulate = args["shouldSimulateError"] as? Bool {
                self.shouldSimulateError = shouldSimulate
            }
            if let intervalNum = args["updateIntervalMs"] as? NSNumber {
                let interval = intervalNum.doubleValue
                if interval < 50 || interval > 10000 {
                    return FlutterError(
                        code: "INVALID_ARGUMENT",
                        message: "updateIntervalMs must be between 50 and 10000 ms",
                        details: interval
                    )
                }
                self.updateIntervalMs = interval
            }
            if let countNum = args["totalCount"] as? NSNumber {
                let countVal = countNum.intValue
                if countVal < 1 || countVal > 1000 {
                    return FlutterError(
                        code: "INVALID_ARGUMENT",
                        message: "totalCount must be between 1 and 1000",
                        details: countVal
                    )
                }
                self.totalCount = countVal
            }
        }
        
        // Ensure any active timer is invalidated before spawning a new one
        invalidateTimer()
        
        // Start Swift Timer (converting ms to seconds)
        let intervalSec = self.updateIntervalMs / 1000.0
        self.timer = Timer.scheduledTimer(
            timeInterval: intervalSec,
            target: self,
            selector: #selector(onTimerTick),
            userInfo: nil,
            repeats: true
        )
        
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // Clean up resources on stream cancellation
        invalidateTimer()
        self.eventSink = nil
        return nil
    }

    @objc private func onTimerTick() {
        guard let sink = self.eventSink else { return }
        
        // Simulate a native failure if configured and count reaches 50
        if shouldSimulateError && count == 50 {
            let errorDetails: [String: Any] = [
                "current": count,
                "total": totalCount,
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "description": "Demonstration of a simulated native stream failure."
            ]
            sink(FlutterError(
                code: "SIMULATED_ERROR",
                message: "Simulated native failure occurred.",
                details: errorDetails
            ))
            invalidateTimer()
            self.eventSink = nil
            return
        }
        
        if count > totalCount {
            // Signal stream completion to the Flutter side
            sink(FlutterEndOfEventStream)
            invalidateTimer()
            self.eventSink = nil
            return
        }
        
        let percentage = Double(count) / Double(totalCount)
        print("Parsing From Native: \(percentage)")
        
        // Construct structured payload map
        let eventPayload: [String: Any] = [
            "type": "progress",
            "current": count,
            "total": totalCount,
            "progress": percentage,
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        sink(eventPayload)
        
        count += 1
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}
