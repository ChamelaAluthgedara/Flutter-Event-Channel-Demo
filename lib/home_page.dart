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

  // TextEditingControllers to allow configuration inputs
  final TextEditingController _intervalController = TextEditingController(text: '200');
  final TextEditingController _countController = TextEditingController(text: '100');

  // Nullable subscription to safely manage listener lifecycle and avoid LateInitializationError
  StreamSubscription<dynamic>? _streamSubscription;
  double _currentValue = 0.0;
  String? _errorMessage;

  // Checks whether the subscription is currently active
  bool get _isListening => _streamSubscription != null;

  void _startListener() {
    // Prevent duplicate subscriptions
    if (_isListening) return;

    setState(() {
      _currentValue = 0.0;
      _errorMessage = null;
    });

    final int? interval = int.tryParse(_intervalController.text);
    final int? count = int.tryParse(_countController.text);

    if (interval == null || count == null) {
      setState(() {
        _errorMessage = "Please enter valid integer values.";
      });
      return;
    }

    // Start listening to the EventChannel broadcast stream, passing configuration arguments
    _streamSubscription = stream.receiveBroadcastStream({
      'updateIntervalMs': interval,
      'totalCount': count,
    }).listen(
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
    if (mounted) {
      setState(() {
        if (error is PlatformException) {
          _errorMessage = "${error.message} (${error.details})";
        } else {
          _errorMessage = error.toString();
        }
        _streamSubscription = null;
        _currentValue = 0.0;
      });
    }
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
    // Cancel the subscription and dispose controllers to prevent resource leaks
    _streamSubscription?.cancel();
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Configuration Inputs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _intervalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Interval (ms)',
                          border: OutlineInputBorder(),
                          helperText: 'Range: 50 - 10000',
                        ),
                        enabled: !_isListening,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _countController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Count',
                          border: OutlineInputBorder(),
                          helperText: 'Range: 1 - 1000',
                        ),
                        enabled: !_isListening,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                height: 30,
              ),

              // Error Display
              if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Start Btn - disabled while listening
              TextButton(
                onPressed: _isListening ? null : _startListener,
                child: Text("Start Counter".toUpperCase()),
              ),
              const SizedBox(
                height: 20,
              ),

              // Cancel Btn - disabled when not listening
              TextButton(
                onPressed: _isListening ? _cancelListener : null,
                child: Text("Cancel Counter".toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
