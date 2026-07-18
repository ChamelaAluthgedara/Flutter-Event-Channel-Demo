# Flutter EventChannel Demo

A simple Flutter example demonstrating how to stream data from native Android code written in Java to Flutter using an https://docs.flutter.dev/platform-integration/platform-channels.

This project sends progress values from Android to Flutter every 200 milliseconds. Flutter receives the values as a stream and displays them using a `LinearProgressIndicator`.

## Demo

https://user-images.githubusercontent.com/53204654/187360492-b18380ef-8518-474c-81c1-2c2942903406.mp4

## What This Project Demonstrates

- Creating an `EventChannel` in native Android (Java/Kotlin) and iOS (Swift)
- Implementing `EventChannel.StreamHandler` / `FlutterStreamHandler`
- Sending continuous data from native platform host to Dart
- Receiving native events as a Dart stream
- Starting, pausing, resuming, and cancelling the event stream
- Updating the Flutter UI with native data
- Handling stream errors and widget lifecycle events

## How It Works

Flutter platform channels allow Dart code to communicate with platform-specific code.

An `EventChannel` is designed for continuous or asynchronous event streams, such as:

- Sensor readings
- Location updates
- Download progress
- Bluetooth events
- Battery information
- Network status changes
- Native service events

In this example, the native Android code generates a value between `0.0` and `1.0` every 200 milliseconds. Flutter receives each value and uses it to update a progress indicator.

## Communication Flow

```text
Android Java
    |
    | EventChannel EventSink
    v
Flutter EventChannel
    |
    | Dart Stream
    v
LinearProgressIndicator
```

Both Android and Flutter must use exactly the same channel name:

```text
com.chamelalaboratory.demo.flutter_event_channel/eventChannel
```

Using different channel names will prevent communication. Using the same channel name for unrelated channels may cause interference.

---

## Native Android Implementation

### Define the EventChannel name

The native Android code defines a constant containing the channel name:

```java
private static final String EVENT_CHANNEL =
        "com.chamelalaboratory.demo.flutter_event_channel/eventChannel";
```

The Flutter application must use the same value.

### Generate progress events

A `Runnable` generates progress values every 200 milliseconds.

The counter runs from `1` to `100`. Each value is divided by `100` to produce a progress value between `0.0` and `1.0`.

```java
private static final int TOTAL_COUNT = 100;
private static final long UPDATE_INTERVAL_MS = 200L;

private int count = 1;

private final Runnable progressRunnable = new Runnable() {
    @Override
    public void run() {
        if (eventSink == null) {
            return;
        }

        if (count > TOTAL_COUNT) {
            eventSink.endOfStream();
            stopEventStream();
            return;
        }

        double progress = (double) count / TOTAL_COUNT;
        eventSink.success(progress);

        Log.d(TAG, "Sending progress to Flutter: " + progress);

        count++;
        handler.postDelayed(this, UPDATE_INTERVAL_MS);
    }
};
```

### Implement `StreamHandler`

The `StreamHandler` provides two callbacks:

- `onListen()` is called when Flutter starts listening.
- `onCancel()` is called when Flutter cancels the subscription.

```java
eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        Log.d(TAG, "Flutter started listening");

        stopEventStream();

        eventSink = events;
        count = 1;
        handler.post(progressRunnable);
    }

    @Override
    public void onCancel(Object arguments) {
        Log.d(TAG, "Flutter cancelled the stream");
        stopEventStream();
    }
});
```

---

## Flutter Implementation

### Create the EventChannel

The Flutter application creates an `EventChannel` using the same channel name as the native Android code:

```dart
static const EventChannel _eventChannel = EventChannel(
  'com.chamelalaboratory.demo.flutter_event_channel/eventChannel',
);
```

### Start listening

Calling `receiveBroadcastStream()` creates the Dart stream.

```dart
void _startListener() {
  if (_streamSubscription != null) {
    return;
  }

  _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
    _onEvent,
    onError: _onError,
    onDone: _onDone,
  );
}
```

### Cancel the subscription

The subscription should be cancelled when it is no longer needed:

```dart
Future<void> _cancelListener() async {
  await _streamSubscription?.cancel();
  _streamSubscription = null;

  if (!mounted) {
    return;
  }

  setState(() {
    _currentValue = 0.0;
  });
}
```

---

## Full Android Code

Add the following code to:

```text
android/app/src/main/java/com/chamelalaboratory/demo/flutter_event_channel/MainActivity.java
```

```java
package com.chamelalaboratory.demo.flutter_event_channel;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;

public class MainActivity extends FlutterActivity {

    private static final String TAG = "FlutterEventChannel";

    private static final String EVENT_CHANNEL =
            "com.chamelalaboratory.demo.flutter_event_channel/eventChannel";

    private static final int TOTAL_COUNT = 100;
    private static final long UPDATE_INTERVAL_MS = 200L;

    private final Handler handler = new Handler(Looper.getMainLooper());

    private EventChannel eventChannel;
    private EventChannel.EventSink eventSink;
    private int count = 1;

    private final Runnable progressRunnable = new Runnable() {
        @Override
        public void run() {
            if (eventSink == null) {
                return;
            }

            if (count > TOTAL_COUNT) {
                eventSink.endOfStream();
                stopEventStream();
                return;
            }

            double progress = (double) count / TOTAL_COUNT;

            Log.d(TAG, "Sending progress to Flutter: " + progress);
            eventSink.success(progress);

            count++;
            handler.postDelayed(this, UPDATE_INTERVAL_MS);
        }
    };

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        eventChannel = new EventChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                EVENT_CHANNEL
        );

        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(
                    Object arguments,
                    EventChannel.EventSink events
            ) {
                Log.d(TAG, "Flutter started listening");

                stopEventStream();

                eventSink = events;
                count = 1;
                handler.post(progressRunnable);
            }

            @Override
            public void onCancel(Object arguments) {
                Log.d(TAG, "Flutter cancelled the stream");
                stopEventStream();
            }
        });
    }

    private void stopEventStream() {
        handler.removeCallbacks(progressRunnable);
        eventSink = null;
        count = 1;
    }

    @Override
    protected void onDestroy() {
        stopEventStream();

        if (eventChannel != null) {
            eventChannel.setStreamHandler(null);
            eventChannel = null;
        }

        super.onDestroy();
    }
}
```

## Full Flutter Code

The following widget listens to the native event stream and displays the received progress value.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const EventChannel _eventChannel = EventChannel(
    'com.chamelalaboratory.demo.flutter_event_channel/eventChannel',
  );

  StreamSubscription<dynamic>? _streamSubscription;

  double _currentValue = 0.0;
  String? _errorMessage;

  bool get _isListening => _streamSubscription != null;

  void _startListener() {
    if (_isListening) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );

    setState(() {});
  }

  void _onEvent(dynamic value) {
    if (!mounted) {
      return;
    }

    final double? progress = switch (value) {
      final num number => number.toDouble(),
      _ => null,
    };

    if (progress == null) {
      _onError(
        PlatformException(
          code: 'INVALID_EVENT',
          message: 'Expected a numeric progress value, but received $value.',
        ),
      );
      return;
    }

    debugPrint('Received progress from Android: $progress');

    setState(() {
      _currentValue = progress.clamp(0.0, 1.0);
      _errorMessage = null;
    });
  }

  void _onError(Object error) {
    debugPrint('EventChannel error: $error');

    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = error.toString();
    });
  }

  void _onDone() {
    debugPrint('The native event stream has finished.');

    _streamSubscription = null;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _cancelListener() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _currentValue = 0.0;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int progressPercentage = (_currentValue * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LinearProgressIndicator(
                  value: _currentValue,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Progress received from Android: $progressPercentage%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _isListening ? null : _startListener,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start stream'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isListening ? _cancelListener : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Cancel stream'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## Getting Started

### Prerequisites

Make sure the following tools are installed:

- Flutter SDK
- Android Studio or Visual Studio Code
- Android SDK
- Java Development Kit
- An Android emulator or physical Android device

Check your Flutter installation:

```bash
flutter doctor
```

### Clone the repository

```bash
git clone https://github.com/ChamelaAluthgedara/Flutter-Event-Channel-Demo.git
cd Flutter-Event-Channel-Demo
```

### Install dependencies

```bash
flutter pub get
```

### Run the application

```bash
flutter run
```

Select an Android emulator or physical Android device when prompted.

> This example contains native Android Java code and is intended to be run on Android.

## Expected Behaviour

1. Open the application on an Android device.
2. Select **Start stream**.
3. Android begins sending progress values to Flutter.
4. Flutter updates the progress indicator.
5. Select **Cancel stream** to stop receiving events and reset the progress.
6. If the progress reaches 100%, Android closes the stream automatically.

## Project Structure

```text
Flutter-Event-Channel-Demo/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── java/
│                   └── com/
│                       └── chamelalaboratory/
│                           └── demo/
│                               └── flutter_event_channel/
│                                   └── MainActivity.java
├── lib/
│   └── main.dart
├── test/
├── LICENSE
├── pubspec.yaml
└── README.md
```

## Troubleshooting

### Flutter does not receive events

Check that the channel name is identical in Java and Dart:

```text
com.chamelalaboratory.demo.flutter_event_channel/eventChannel
```

Channel names are case-sensitive.

### `MissingPluginException`

Try stopping and rebuilding the application:

```bash
flutter clean
flutter pub get
flutter run
```

A hot reload may not apply changes made to native Android code.

### The stream continues after leaving the page

Ensure the Flutter subscription is cancelled in `dispose()` and that native callbacks are removed when the stream is cancelled.

### iOS Pod Installation Issues

Both Android and iOS are fully supported. If you encounter issues on iOS, make sure you run cocoapods installation in the `ios/` directory before building the application:
```bash
cd ios && pod install
```

## Ideas for Future Improvements

- [x] Add a native Android Kotlin implementation
- [x] Add an iOS Swift implementation
- [x] Add automated Flutter tests
- [ ] Add native error-event examples
- [ ] Demonstrate passing arguments from Flutter to Android
- [ ] Add sensor-data and location-stream examples
- [ ] Add application lifecycle handling examples
- [ ] Create a reusable Flutter plugin version
- [ ] Add GitHub Actions for automated analysis and testing

## Contributing

Contributions, bug reports, documentation improvements, and suggestions are welcome.

To contribute:

1. Fork this repository.
2. Create a feature branch.
3. Make and test your changes.
4. Submit a pull request with a clear description.

Please ensure that your code is formatted and passes Flutter analysis:

```bash
dart format .
flutter analyze
flutter test
```

## License

This project is available under the LICENSE.
