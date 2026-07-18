# EventChannel Development Guide

This guide provides a comprehensive overview of how to implement, test, and troubleshoot `EventChannel` streams in Flutter for asynchronous, push-based native-to-Dart communication.

---

## 1. Architectural Overview

An `EventChannel` is used for streaming continuous data from the native host platform (Android/iOS) to the Flutter Dart client. Unlike `MethodChannel` (which is request-response), `EventChannel` is unidirectional and push-based.

```text
  Flutter Dart                                Native Host
 ┌────────────┐                              ┌───────────┐
 │ Stream.    │ ◄─── Binary Message Pipe ─── │ EventSink │
 │ listen()   │                              └───────────┘
 └────────────┘                                    ▲
       │                                           │
       ▼                                           │
   onListen(args) ─────────────────────────────────┘
```

---

## 2. Implementing the Native Handlers

Conform to the native stream handler interfaces (`EventChannel.StreamHandler` on Android, `FlutterStreamHandler` on iOS).

### 2.1. Android Java
```java
EventChannel channel = new EventChannel(messenger, "channel_name");
channel.setStreamHandler(new EventChannel.StreamHandler() {
    private EventChannel.EventSink eventSink;

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.eventSink = events;
        // Start emitting events...
        events.success(data);
    }

    @Override
    public void onCancel(Object arguments) {
        // Clean up resources (e.g. stop timers, clear sink reference)
        this.eventSink = null;
    }
});
```

### 2.2. Android Kotlin
```kotlin
val channel = EventChannel(messenger, "channel_name")
channel.setStreamHandler(object : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        // Start emitting events...
        events?.success(data)
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null;
    }
})
```

### 2.3. iOS Swift
```swift
let channel = FlutterEventChannel(name: "channel_name", binaryMessenger: messenger)
class StreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // Start emitting events...
        events(data)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
channel.setStreamHandler(StreamHandler())
```

---

## 3. Dart Subscription Management

To listen to a stream in Flutter:

```dart
static const stream = EventChannel('channel_name');
StreamSubscription<dynamic>? _subscription;

void startListening() {
  _subscription = stream.receiveBroadcastStream(arguments).listen(
    (event) {
      // Process successful event
    },
    onError: (error) {
      // Process stream error
    },
    onDone: () {
      // Handle stream completion
    },
    cancelOnError: false,
  );
}
```

---

## 4. Passing Arguments

You can pass configuration parameters from Dart to the native host inside `receiveBroadcastStream(arguments)`. These are serialized using the `StandardMessageCodec` and delivered to `onListen` as a Map/List/String.

### Validation Best Practice:
Always validate arguments on the native side. If arguments are invalid, return a `FlutterError` (iOS) or call `events.error` (Android) to cleanly reject the connection:

```kotlin
// Android Validation Example
(args["totalCount"] as? Number)?.let {
    val count = it.toInt()
    if (count < 1) {
        events?.error("INVALID_ARGUMENT", "totalCount must be >= 1", count)
        return
    }
}
```

---

## 5. Preventing Resource and Memory Leaks

* **Timer Invalidation:** Always cancel/invalidate native timers (`Handler.removeCallbacks` on Android, `Timer.invalidate()` on iOS) inside `onCancel`.
* **Nullify EventSinks:** Set the `EventSink` reference to `null` inside `onCancel` to prevent sending messages to disposed channels (which causes native crashes).
* **Widget Lifecycle:** Always cancel the Dart `StreamSubscription` in the Widget's `dispose()` method.
* **App Lifecycle:** Use an `AppLifecycleListener` to cancel subscriptions when the app enters the background, and restart them when returning to the foreground.

---

## 6. Testing Event Channels

### 6.1. Mocking at the Binary Messenger Level (Widget & Integration Tests)
You can intercept method calls and push mock raw events directly:

```dart
const channelName = 'channel_name';

// Mock the connection handler
tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
  const MethodChannel(channelName),
  (MethodCall methodCall) async {
    return null; // Return success envelope
  },
);

// Inject/emit a mock event envelope
final ByteData eventData = const StandardMethodCodec().encodeSuccessEnvelope(payload);
await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
  channelName,
  eventData,
  null,
);
```

### 6.2. Dependency Injection (Unit Tests)
Instead of hardcoding `EventChannel`, pass a `StreamFactory` or the `Stream` reference itself to your controller classes, enabling pure Dart unit tests without mock bindings.
