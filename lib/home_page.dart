import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'progress_event.dart';

/// The various operational states of the EventChannel subscription.
enum StreamState { idle, running, paused, completed, cancelled, error }

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

  // Nullable subscription to safely manage listener lifecycle
  StreamSubscription<dynamic>? _streamSubscription;
  double _currentValue = 0.0;
  String? _errorMessage;
  bool _shouldSimulateError = false;

  // Stream state tracking
  StreamState _state = StreamState.idle;

  // Checks whether the subscription is active (either running or paused)
  bool get _isListening => _streamSubscription != null;

  void _startListener() {
    if (_isListening) return;

    setState(() {
      _currentValue = 0.0;
      _errorMessage = null;
      _state = StreamState.running;
    });

    final int? interval = int.tryParse(_intervalController.text);
    final int? count = int.tryParse(_countController.text);

    if (interval == null || count == null) {
      setState(() {
        _errorMessage = "Please enter valid integer values.";
        _state = StreamState.error;
      });
      return;
    }

    // Start listening to the EventChannel broadcast stream
    _streamSubscription = stream.receiveBroadcastStream({
      'updateIntervalMs': interval,
      'totalCount': count,
      'shouldSimulateError': _shouldSimulateError,
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
        _state = StreamState.cancelled;
      });
    }
  }

  void _pauseListener() {
    if (_state == StreamState.running) {
      _streamSubscription?.pause();
      setState(() {
        _state = StreamState.paused;
      });
    }
  }

  void _resumeListener() {
    if (_state == StreamState.paused) {
      _streamSubscription?.resume();
      setState(() {
        _state = StreamState.running;
      });
    }
  }

  void _listenStream(dynamic value) {
    debugPrint("Received From Native: $value\n");

    if (value is! Map) {
      debugPrint("Warning: received non-map value from native: $value");
      return;
    }

    try {
      final event = ProgressEvent.fromMap(value);
      if (mounted) {
        setState(() {
          _currentValue = event.progress.clamp(0.0, 1.0);
        });
      }
    } catch (e) {
      debugPrint("Error parsing progress event: $e");
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
        _state = StreamState.error;
      });
    }
  }

  void _handleDone() {
    debugPrint("Native stream completed.");
    _streamSubscription?.cancel();
    if (mounted) {
      setState(() {
        _streamSubscription = null;
        _state = StreamState.completed;
      });
    }
  }

  @override
  void dispose() {
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

              // Error Simulation Switch
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: SwitchListTile(
                  title: const Text('Simulate Native Error (Fails at 50%)'),
                  value: _shouldSimulateError,
                  onChanged: _isListening
                      ? null
                      : (bool value) {
                          setState(() {
                            _shouldSimulateError = value;
                          });
                        },
                ),
              ),
              const SizedBox(height: 10),

              // State Status Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  "STATUS: ${_state.name.toUpperCase()}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _state == StreamState.running
                        ? Colors.green
                        : _state == StreamState.paused
                            ? Colors.orange
                            : _state == StreamState.error
                                ? Colors.red
                                : Colors.blueGrey,
                  ),
                ),
              ),
              const SizedBox(height: 15),

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
                height: 20,
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

              // Controls Panel
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  // Start Btn
                  ElevatedButton(
                    onPressed: _isListening ? null : _startListener,
                    child: Text("Start".toUpperCase()),
                  ),

                  // Pause / Resume Btn
                  if (_state == StreamState.running)
                    ElevatedButton(
                      onPressed: _pauseListener,
                      child: Text("Pause".toUpperCase()),
                    )
                  else if (_state == StreamState.paused)
                    ElevatedButton(
                      onPressed: _resumeListener,
                      child: Text("Resume".toUpperCase()),
                    ),

                  // Cancel Btn
                  ElevatedButton(
                    onPressed: _isListening ? _cancelListener : null,
                    child: Text("Cancel".toUpperCase()),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Educational disclaimer about pause vs cancel
              if (_isListening)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "💡 Note: Pausing the Dart stream subscription buffers event delivery but does NOT stop native Android progress generation. Use 'Cancel' to stop native resources entirely.",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
