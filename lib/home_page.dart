import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const stream = EventChannel('com.chamelalaboratory.demo.flutter_event_channel/eventChannel');

  // Nullable subscription to safely manage listener lifecycle and avoid LateInitializationError
  StreamSubscription<dynamic>? _streamSubscription;
  double _currentValue = 0.0;

  // Checks whether the subscription is currently active
  bool get _isListening => _streamSubscription != null;

  void _startListener() {
    // Prevent duplicate subscriptions
    if (_isListening) return;

    setState(() {
      _currentValue = 0.0;
    });

    // Start listening to the EventChannel broadcast stream
    _streamSubscription = stream.receiveBroadcastStream().listen(
      _listenStream,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  void _cancelListener() {
    _streamSubscription?.cancel();
    if (mounted) {
      setState(() {
        _streamSubscription = null;
        _currentValue = 0.0;
      });
    }
  }

  void _listenStream(dynamic value) {
    debugPrint("Received From Native: $value\n");

    // Validate that the native event is a numeric type
    if (value is! num) {
      debugPrint("Warning: received non-numeric value from native: $value");
      return;
    }

    if (mounted) {
      setState(() {
        // Clamp the progress values between 0.0 and 1.0 to prevent layout/drawing issues
        _currentValue = value.toDouble().clamp(0.0, 1.0);
      });
    }
  }

  void _handleError(Object error) {
    debugPrint("Error received from native stream: $error");
    // Clean up subscription upon receiving stream error
    _cancelListener();
  }

  void _handleDone() {
    debugPrint("Native stream completed.");
    _streamSubscription?.cancel();
    if (mounted) {
      setState(() {
        _streamSubscription = null;
      });
    }
  }

  @override
  void dispose() {
    // Cancel the subscription on widget disposal to prevent memory and native stream leaks
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                value: _currentValue,
                backgroundColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(
              height: 5,
            ),

            // Value in text
            Text(
              "Received Stream From Native: $_currentValue".toUpperCase(),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(
              height: 50,
            ),

            // Start Btn - disabled while listening
            TextButton(
              onPressed: _isListening ? null : _startListener,
              child: Text("Start Counter".toUpperCase()),
            ),
            const SizedBox(
              height: 50,
            ),

            // Cancel Btn - disabled when not listening
            TextButton(
              onPressed: _isListening ? _cancelListener : null,
              child: Text("Cancel Counter".toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}
