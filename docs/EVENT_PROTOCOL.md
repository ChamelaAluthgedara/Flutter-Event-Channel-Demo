# EventChannel Protocol Specification

This document defines the communication contract and protocol structure used between the Flutter application and the native host platforms via the `EventChannel`.

---

## 1. Channel Identifier

Both client (Flutter/Dart) and host (Android/Java) must use the identical channel name:

```text
com.chamelalaboratory.demo.flutter_event_channel/eventChannel
```

---

## 2. Stream Configuration Arguments

When the client starts listening to the event stream, it can pass configuration arguments as a Map (`Map<String, dynamic>` in Dart, parsed as `Map<?, ?>` in Java).

| Parameter Name | Data Type | Default Value | Valid Range | Description |
|---|---|---|---|---|
| `updateIntervalMs` | Integer | `200` | `50` to `10000` | The interval in milliseconds at which the native side generates and streams the progress events. |
| `totalCount` | Integer | `100` | `1` to `1000` | The total number of events generated before the stream automatically finishes. |

### Example Client Subscription Call
```dart
EventChannel('com.chamelalaboratory.demo.flutter_event_channel/eventChannel')
    .receiveBroadcastStream({
      'updateIntervalMs': 200,
      'totalCount': 100,
    });
```

---

## 3. Event Payload (Success)

Each progress tick emits a raw floating-point number representing progress percentage.

* **Format:** Single numeric value (`double` in Dart / `Double` in Java).
* **Values:** `0.0` to `1.0` (where `1.0` represents 100% completion).
* **Formula:** `progress = (double) currentTick / totalCount`.

---

## 4. Error Payload

If configuration parameters are invalid, the native stream handler will not start the timer. Instead, it immediately emits an error event via the platform channel.

* **Dart Exception Type:** `PlatformException`
* **Fields:**
  * `code`: `"INVALID_ARGUMENT"`
  * `message`: A descriptive string specifying which parameter failed validation and why.
  * `details`: The actual out-of-bounds value passed by the client.

---

## 5. Lifecycle and Stream Completion

* **Completion:** When the count of events exceeds `totalCount`, the native platform code invokes `endOfStream()` on the active event sink.
* **Dart Handler:** The Dart stream triggers its `onDone` callback, and the client closes the subscription.
* **Auto-Rescheduling Stop:** The native tick scheduler immediately cancels any further events, releasing the timer resource.
