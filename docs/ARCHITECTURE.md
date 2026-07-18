# System Architecture Documentation

This document describes the architectural layout, boundaries, component relationships, and data flow pipelines of the Flutter Event Channel Demo project.

---

## 1. System Architecture Diagram

Below is a high-level representation of the components, showcasing the separation of UI, state controller, platform channel boundaries, and native business logic:

```text
 ┌─────────────────────────────────────────────────────────────┐
 │                         FLUTTER DART                        │
 │                                                             │
 │   ┌───────────────────────┐       ┌─────────────────────┐   │
 │   │      MyHomePage       │ ◄──── │  StreamLifecycle-   │   │
 │   │      (UI Layer)       │       │     Controller      │   │
 │   └───────────────────────┘       └─────────────────────┘   │
 │               │                                             │
 │               ▼                                             │
 │   ┌───────────────────────┐                                 │
 │   │    ProgressStream-    │                                 │
 │   │      Controller       │                                 │
 │   └───────────────────────┘                                 │
 └───────────────┼─────────────────────────────────────────────┘
                 │
  Dart-Native    │ EventChannel (StandardMethodCodec / BinaryMessenger)
  Boundary       ▼
 ┌─────────────────────────────────────────────────────────────┐
 │                         NATIVE HOST                         │
 │                                                             │
 │   ┌─────────────────────────────────────────────────────┐   │
 │   │                 PLATFORM ENGINES                    │   │
 │   │   Android: MainActivity    │   iOS: AppDelegate     │   │
 │   └────────────────────────────┼────────────────────────┘   │
 │                                │                            │
 │       ┌────────────────────────┴────────────────────┐       │
 │       ▼                                             ▼       │
 │  [Android Java/Kotlin]                         [iOS Swift]  │
 │  ┌──────────────────────┐              ┌──────────────────┐ │
 │  │  ProgressGenerator  │              │ ProgressStream-  │ │
 │  │    (Pure Logic)      │              │     Handler      │ │
 │  └──────────────────────┘              └──────────────────┘ │
 │  ┌──────────────────────┐              ┌──────────────────┐ │
 │  │   BroadcastReceiver  │              │ Notification-    │ │
 │  │   (Battery Intent)   │              │  Center Observer │ │
 │  └──────────────────────┘              └──────────────────┘ │
 └─────────────────────────────────────────────────────────────┘
```

---

## 2. Platform Boundaries and Data Codecs

Communication between Dart and the native hosts runs across standard platform channels:

* **Channel Boundary:** An `EventChannel` creates a named, unidirectional stream connection. Both Dart and native sides must register the exact same channel identifier.
* **Message Serialization:** Payloads are serialized using Flutter's `StandardMethodCodec` which maps Dart collections (like `Map<String, dynamic>`, `int`, `double`) into native equivalents (`Map<String, Object>` in Java/Kotlin, `[String: Any]` in Swift) and vice versa over the binary messenger pipeline.

---

## 3. Component Responsibilities

### 3.1. Flutter (Dart) Layer
1. **`MyHomePage` (UI View):** Handles presentation rendering (segmented buttons, selectors, progress indicators, battery shapes).
2. **`ProgressStreamController` (State Controller):** Isolates the EventChannel subscription, tracks state status (`idle`, `running`, `paused`, `completed`, `cancelled`, `error`), and performs type-safe parsing using `ProgressEvent`. Supporting injected stream factories makes it 100% testable without native devices.
3. **`StreamLifecycleController` (Lifecycle Observer):** Listens to global app state changes (`paused`, `resumed`, `hidden`) and triggers background subscription releases and foreground auto-restarts.

### 3.2. Native Host Layer
1. **MainActivity / AppDelegate (Platform Wiring):** Registers stream handlers and handles argument parsing from Flutter.
2. **ProgressGenerator (Android Business Logic):** Extracted pure Java class holding logic for increment rules, interval delays, error thresholds, and parameter boundary validations.
3. **ProgressStreamHandler / BatteryStreamHandler (iOS/Swift Handlers):** Manages timer scheduling, clean cancellation logic, and battery notification registration.

---

## 4. Resource Cleanup Sequence

To ensure background processes do not leak, the cleanup workflow always follows this sequence:

```text
    Dart Subscription Cancelled (or App backgrounded)
                       │
                       ▼
          Invoke Native `onCancel()`
                       │
                       ▼
    Stop Native Loop (Timer Invalidation / Handler Callback Clear)
                       │
                       ▼
             Nullify native EventSink
```
