# EventChannel Troubleshooting Recipes

This document lists common problems, build errors, and runtime failures when working with `EventChannel` streams, along with detailed solutions to resolve them.

---

## 1. Native Build Failures

### 1.1. Android: JDK Mismatches
* **Symptom:** Gradle build failures referencing unsupported class file versions or compiled Java constraints.
* **Cause:** The project requires JDK 17 to compile the modernized build configs.
* **Solution:** Verify that your local Java development kit is configured to JDK 17:
  ```bash
  java -version
  ```
  Ensure your IDE (Android Studio or VS Code) has its Gradle JDK target configured to JDK 17.

### 1.2. Android: Duplicate MainActivity Classes
* **Symptom:** `Type MainActivity is defined multiple times` error during build compile phase.
* **Cause:** Both `MainActivity.java` and `MainActivity.kt` (under kotlin sources) are active at the same time.
* **Solution:** Follow [KOTLIN_GUIDE.md](file:///Users/chamelaaluthgedara/Development/Flutter-Event-Channel-Demo/docs/KOTLIN_GUIDE.md) to ensure only one main activity file has the compiling extension (`.java` or `.kt`) while the other uses `.example`.

### 1.3. iOS: CocoaPods Configuration Issues
* **Symptom:** iOS build failures when compiling the Swift runner.
* **Cause:** Outdated Pod configurations or missing generated plugin registrants.
* **Solution:** Navigate to the `ios/` folder and run pod installation:
  ```bash
  cd ios
  pod install
  ```
  Ensure you are opening `Runner.xcworkspace` in Xcode rather than the flat project file.

---

## 2. EventChannel Runtime Failures

### 2.1. Uncaught Native Crashes (Emitting on Null Sinks)
* **Symptom:** Native crashes on Android (`NullPointerException`) or iOS when emitting events.
* **Cause:** The background thread attempts to emit events after the client has cancelled the stream subscription, meaning the native `EventSink` has been disposed or nullified.
* **Solution:** Always check that the sink reference is not null before dispatching events:
  * **Java/Kotlin:** `if (attachEvent != null) { attachEvent.success(data); }`
  * **Swift:** `guard let sink = self.eventSink else { return }`

### 2.2. CPU and Battery Drain (Lifecycle Leaks)
* **Symptom:** High battery usage or active background CPU consumption when the app is in the background.
* **Cause:** The native background timers (`Handler` on Android, `Timer` on iOS) continue running even though the Dart subscriber is paused or the app is minimized.
* **Solution:** Ensure the native stream handlers stop all scheduling loops when `onCancel` is called. Implement an `AppLifecycleListener` in Flutter to cancel active subscriptions when the app goes background.

### 2.3. PlatformException: INVALID_ARGUMENT
* **Symptom:** Dart receives an error containing `PlatformException(INVALID_ARGUMENT, ...)` immediately upon listening.
* **Cause:** Parameters passed to `receiveBroadcastStream(arguments)` are out of bounds (such as interval < 50ms or count > 1000).
* **Solution:** Adjust the input values to reside within the validation limits documented in [EVENT_PROTOCOL.md](file:///Users/chamelaaluthgedara/Development/Flutter-Event-Channel-Demo/docs/EVENT_PROTOCOL.md).
