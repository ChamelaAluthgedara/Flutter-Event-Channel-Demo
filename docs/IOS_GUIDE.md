# iOS Swift EventChannel Implementation Guide

This document outlines the iOS native implementation of the `EventChannel` stream handler in Swift and explains its architectural details, timer lifecycle management, and troubleshooting strategies.

---

## 1. Code Structure and Responsibilities

The iOS implementation is written in Swift and consists of two main integration files:

1. **[AppDelegate.swift](file:///Users/chamelaaluthgedara/Development/Flutter-Event-Channel-Demo/ios/Runner/AppDelegate.swift)**
   * Registers the application plugins and lifecycle bridges.
   * Intercepts implicit Flutter engine initialization via `didInitializeImplicitFlutterEngine`.
   * Instantiates the `FlutterEventChannel` with the channel name and registers the `ProgressStreamHandler`.
2. **[ProgressStreamHandler.swift](file:///Users/chamelaaluthgedara/Development/Flutter-Event-Channel-Demo/ios/Runner/ProgressStreamHandler.swift)**
   * Conforms to the `FlutterStreamHandler` protocol.
   * Manages the lifecycle of a scheduled Swift `Timer` to emit periodic events.
   * Extracts and validates arguments (`updateIntervalMs`, `totalCount`, `shouldSimulateError`) passed from Dart.
   * Serializes success event maps and error objects using Flutter's standard codecs.

---

## 2. Timer Lifecycle and Resource Management

To prevent resource leaks and duplicate event loops on iOS, the following safeguards are implemented in Swift:

* **Preventing Duplicate Timers:** In `onListen`, the code calls `invalidateTimer()` prior to instantiating a new `Timer`. This ensures that if a stream is restarted without a clean cancel, any existing background timers are immediately stopped and released.
* **Cleaning Up on Cancellation:** The `onCancel` method executes `invalidateTimer()` and nullifies the `eventSink` pointer.
* **Auto-completion Cleanup:** When `count` exceeds `totalCount` (or when a simulated error triggers), the timer is invalidated inside `onTimerTick()`, halting further execution cycles.

```swift
private func invalidateTimer() {
    timer?.invalidate()
    timer = nil
}
```

---

## 3. Data Mapping and Validation

### 3.1. Parsing Dart Arguments
Flutter arguments passed to `receiveBroadcastStream(arguments)` are mapped to Swift types as follows:

* Dart `Map<String, dynamic>` compiles to Swift `[String: Any]`.
* Dart integers are wrapped in `NSNumber`.
* Dart booleans cast to Swift `Bool`.

```swift
if let args = arguments as? [String: Any] {
    if let intervalNum = args["updateIntervalMs"] as? NSNumber {
        let interval = intervalNum.doubleValue
        // Validation logic
    }
}
```

### 3.2. Mapping Swift Errors to Flutter
If arguments are out of bounds or a simulated error triggers, Swift creates and returns a `FlutterError`:

```swift
return FlutterError(
    code: "INVALID_ARGUMENT",
    message: "updateIntervalMs must be between 50 and 10000 ms",
    details: interval
)
```

In Dart, this is received and parsed as a `PlatformException`.

---

## 4. Troubleshooting and Build Recipes

### 4.1. Missing Pods/Build Errors
If the iOS build fails with CocoaPods dependencies or runner workspace issues:
1. Navigate to the `ios/` folder:
   ```bash
   cd ios
   ```
2. Reinstall Pod dependencies:
   ```bash
   pod install
   ```

### 4.2. Hot Reload Limitation
Changes made to native Swift code (such as modifies in `ProgressStreamHandler.swift`) will **not** be picked up by Flutter's hot reload. You must perform a full stop and run:
```bash
flutter clean
flutter run
```
