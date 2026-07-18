# EventChannel Protocol Specification

This document defines the communication contract and protocol structure used between the Flutter application and the native host platforms via the `EventChannel`.

---

## 1. Channel Identifiers

This project exposes two separate, independent event streams:

1. **Progress Stream:**
   ```text
   com.chamelalaboratory.demo.flutter_event_channel/eventChannel
   ```
2. **Battery Status Stream:**
   ```text
   com.chamelalaboratory.demo.flutter_event_channel/batteryChannel
   ```

---

## 2. Progress Stream Contract (`eventChannel`)

### 2.1. Stream Configuration Arguments
When the client starts listening, it passes configuration parameters as a Map:

| Parameter Name | Data Type | Default Value | Valid Range | Description |
|---|---|---|---|---|
| `updateIntervalMs` | Integer | `200` | `50` to `10000` | The interval in milliseconds at which the native side generates and streams the progress events. |
| `totalCount` | Integer | `100` | `1` to `1000` | The total number of events generated before the stream automatically finishes. |
| `shouldSimulateError` | Boolean | `false` | `true` / `false` | If true, the native side will simulate a platform error when the progress ticks reach 50. |

### 2.2. Event Payload (Success)
Each progress tick emits a serialized Map containing detailed event state parameters:
* **Format:** Map (`Map<String, dynamic>` in Dart / `Map<String, Object>` in Java / `[String: Any]` in Swift).
* **Fields:**
  * `type` (String): The type of event. For progress ticks, this is always `"progress"`.
  * `current` (Integer): The 1-based index of the current progress tick.
  * `total` (Integer): The configured target `totalCount` for this stream run.
  * `progress` (Double): The calculated completion percentage, clamped between `0.0` and `1.0`.
  * `timestamp` (Integer): System epoch timestamp in milliseconds when the event was generated on the host platform.

### 2.3. Error Payload
Errors encountered or simulated on the native side are sent to the stream sink via `events.error(code, message, details)`. In Dart, these events are delivered as error payloads wrapped in a `PlatformException`.

#### PlatformException Mapping:
* `code` (String): Unique identifier (`"INVALID_ARGUMENT"`, `"SIMULATED_ERROR"`).
* `message` (String): Human-readable error description.
* `details` (Map/Integer): Out-of-bounds parameters or simulated error details (current count, total count, timestamp, description).

---

## 3. Battery Status Stream Contract (`batteryChannel`)

### 3.1. Stream Configuration Arguments
No arguments are required. The subscription is initiated without parameter maps:
```dart
batteryStream.receiveBroadcastStream();
```

### 3.2. Event Payload (Success)
Emitted only when the device's battery level or charging state changes (on Android, using a `BroadcastReceiver` listening to `Intent.ACTION_BATTERY_CHANGED`; on iOS, using `NotificationCenter` observing `UIDevice.batteryLevelDidChangeNotification` and `UIDevice.batteryStateDidChangeNotification`).

* **Format:** Map (`Map<String, dynamic>` in Dart / `Map<String, Object>` in Java / `[String: Any]` in Swift).
* **Fields:**
  * `level` (Double): The battery charge percentage, ranging from `0.0` (empty) to `1.0` (fully charged). (Defaults to `0.0` on Simulators if unavailable).
  * `isCharging` (Boolean): `true` if the device is plugged in and actively charging or full; `false` otherwise.

---

## 4. When to Use EventChannel vs. MethodChannel

Selecting the correct platform integration channel is critical for performance and resource usage:

| Feature | MethodChannel | EventChannel |
|---|---|---|
| **Communication Style** | **Pull-based** (Request-Response / RPC style). | **Push-based** (Unidirectional stream). |
| **Data Flow** | Dart triggers an action, and the native side returns a single result. | Native side streams continuous, asynchronous events as they happen. |
| **Control** | Orchestrated by Dart (synchronous/asynchronous calls). | Native side determines when events are fired; Dart subscribes/unsubscribes. |
| **Typical Use Cases** | <ul><li>Retrieving current state once (e.g. get device model, get single location).</li><li>Triggering native actions (e.g. save file, trigger camera).</li></ul> | <ul><li>Listening to hardware sensors (accelerometer, gyroscope).</li><li>Streaming location updates in real-time.</li><li>Observing system notifications (battery status, connectivity state changes).</li></ul> |
