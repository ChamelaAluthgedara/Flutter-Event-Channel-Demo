# Application Lifecycle and Resource Management

This document defines how the Flutter Event Channel Demo application responds to state changes in the application lifecycle.

---

## 1. Lifecycle Policy Architecture

To ensure the native host's event generation does not leak memory or waste CPU/battery when the application is placed in the background, a lifecycle policy is implemented using Flutter's modern `AppLifecycleListener` API.

The lifecycle monitoring policy is encapsulated in a dedicated controller ([stream_lifecycle_controller.dart](file:///Users/chamelaaluthgedara/Development/Flutter-Event-Channel-Demo/lib/stream_lifecycle_controller.dart)) separate from the UI widgets.

```text
       Flutter Engine State
                │
                ▼
    StreamLifecycleController
                │
                ├─────────► [paused/hidden] ──► Cancel Subscription (Releases Native Timer)
                │
                └─────────► [resumed] ────────► Auto-Restart (If active before pause)
```

---

## 2. Detailed Lifecycle State Behaviors

| Lifecycle State | Description | Application Behavior | Resource Impact |
|---|---|---|---|
| **`inactive`** | The app is visible but has lost focus (e.g. system overlay, notification tray, split-screen mode). | The EventChannel **remains active**, and updates continue. | Minimal. UI remains responsive. |
| **`hidden`** | The app is completely hidden from view (typically immediately preceding `paused` on modern systems). | The stream subscription is **cancelled**. If active, it saves state: `_wasListeningBeforePause = true`. | Excellent. Stops background execution. |
| **`paused`** | The app is running in the background (not visible to the user). | The stream subscription is **cancelled** (if not already done by `hidden`). Saves active state. | Excellent. Native `stopEventStream()` stops the Android `Handler` loop entirely. |
| **`resumed`** | The app returns to the foreground and is visible/focused. | If `_wasListeningBeforePause` is `true`, it **automatically restarts** the stream. | Resumes UI updating. Native timer is safe-started without duplicates. |
| **`detached`** | The application is still running but detached from any host view/activity (termination phase). | The widget tree is unmounted. `dispose()` is triggered, which cleans up the listener and controllers. | Zero. All resources garbage-collected. |

---

## 3. Native Callback Clean Up

When the subscription is cancelled due to a `paused` or `hidden` state transition:
1. Flutter calls `cancel` on the `StreamSubscription`.
2. This invokes the native Android `onCancel` method in `MainActivity.java`.
3. Native code executes `stopEventStream()`, which:
   * Safely calls `handler.removeCallbacks(runnable)`.
   * Sets the `attachEvent` sink reference to `null`.
   * Prevents any future `postDelayed` self-rescheduling cycles.
4. When returning to the foreground, `_startListener()` initiates a new subscription, registering a new stream handler on the native side without overlapping or creating duplicate timers.
