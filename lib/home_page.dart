import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'progress_stream_controller.dart';
import 'stream_lifecycle_controller.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const batteryStream = EventChannel('com.chamelalaboratory.demo.flutter_event_channel/batteryChannel');

  // Currently selected demo tab: 0 for Progress Counter, 1 for Battery Status
  int _selectedDemoIndex = 0;

  // --- Progress Controller & State ---
  late final ProgressStreamController _progressController;
  final TextEditingController _intervalController = TextEditingController(text: '200');
  final TextEditingController _countController = TextEditingController(text: '100');
  bool _shouldSimulateError = false;
  String? _localErrorMessage;
  bool _wasListeningBeforePause = false;

  // --- Battery Demo State ---
  StreamSubscription<dynamic>? _batterySubscription;
  double _batteryLevel = 0.0;
  bool _isBatteryCharging = false;
  bool _isBatteryListening = false;
  bool _wasBatteryListeningBeforePause = false;

  // Lifecycle controller to handle app background/foreground transitions
  late final StreamLifecycleController _lifecycleController;

  @override
  void initState() {
    super.initState();
    
    // Initialize the ProgressStreamController and rebuild on updates
    _progressController = ProgressStreamController(
      onUpdate: () {
        if (mounted) setState(() {});
      },
    );

    _lifecycleController = StreamLifecycleController(
      onPauseApp: _handleAppPause,
      onResumeApp: _handleAppResume,
    );
  }

  // --- Progress Demo Controls ---
  void _startListener() {
    final int? interval = int.tryParse(_intervalController.text);
    final int? count = int.tryParse(_countController.text);

    if (interval == null || count == null) {
      setState(() {
        _localErrorMessage = "Please enter valid integer values.";
      });
      return;
    }

    setState(() {
      _localErrorMessage = null;
    });

    _progressController.start(
      intervalMs: interval,
      totalCount: count,
      shouldSimulateError: _shouldSimulateError,
    );
  }

  void _cancelListener() {
    _progressController.cancel();
  }

  void _pauseListener() {
    _progressController.pause();
  }

  void _resumeListener() {
    _progressController.resume();
  }

  // --- Battery Demo Controls ---
  void _startBatteryListener() {
    if (_isBatteryListening) return;

    setState(() {
      _batteryLevel = 0.0;
      _isBatteryCharging = false;
      _isBatteryListening = true;
    });

    _batterySubscription = batteryStream.receiveBroadcastStream().listen(
      _listenBatteryStream,
      onError: _handleBatteryError,
      onDone: _handleBatteryDone,
    );
  }

  void _cancelBatteryListener() {
    _batterySubscription?.cancel();
    if (mounted) {
      setState(() {
        _batterySubscription = null;
        _isBatteryListening = false;
      });
    }
  }

  void _listenBatteryStream(dynamic value) {
    debugPrint("Received Battery From Native: $value\n");
    if (value is! Map) return;

    if (mounted) {
      setState(() {
        _batteryLevel = (value['level'] as num).toDouble().clamp(0.0, 1.0);
        _isBatteryCharging = value['isCharging'] as bool;
      });
    }
  }

  void _handleBatteryError(Object error) {
    debugPrint("Battery stream error: $error");
    _cancelBatteryListener();
  }

  void _handleBatteryDone() {
    _cancelBatteryListener();
  }

  // --- App Lifecycle Handlers ---
  void _handleAppPause() {
    // Save state and release native resources when app goes to background
    if (_progressController.isListening) {
      _wasListeningBeforePause = true;
      _cancelListener();
    }
    if (_isBatteryListening) {
      _wasBatteryListeningBeforePause = true;
      _cancelBatteryListener();
    }
  }

  void _handleAppResume() {
    // Automatically resume listening when returning to foreground
    if (_wasListeningBeforePause) {
      _wasListeningBeforePause = false;
      _startListener();
    }
    if (_wasBatteryListeningBeforePause) {
      _wasBatteryListeningBeforePause = false;
      _startBatteryListener();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _batterySubscription?.cancel();
    _intervalController.dispose();
    _countController.dispose();
    _lifecycleController.dispose();
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
          children: [
            // Demo Selector Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<int>(
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 0, icon: Icon(Icons.timer), label: Text('Progress Counter')),
                  ButtonSegment<int>(value: 1, icon: Icon(Icons.battery_charging_full), label: Text('Battery Status')),
                ],
                selected: <int>{_selectedDemoIndex},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    // Cancel all active streams when switching tabs
                    _cancelListener();
                    _cancelBatteryListener();
                    _selectedDemoIndex = newSelection.first;
                  });
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: _selectedDemoIndex == 0 ? _buildProgressDemo() : _buildBatteryDemo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDemo() {
    final displayError = _localErrorMessage ?? _progressController.errorMessage;
    final state = _progressController.state;
    final isListening = _progressController.isListening;
    final progress = _progressController.progress;

    return Column(
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
                  enabled: !isListening,
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
                  enabled: !isListening,
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
            onChanged: isListening
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
            "STATUS: ${state.name.toUpperCase()}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: state == StreamState.running
                  ? Colors.green
                  : state == StreamState.paused
                      ? Colors.orange
                      : state == StreamState.error
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
            value: progress,
            backgroundColor: Colors.blue.shade50,
          ),
        ),
        const SizedBox(
          height: 5,
        ),

        // Value in text
        Text(
          "Received Stream From Native: $progress".toUpperCase(),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(
          height: 20,
        ),

        // Error Display
        if (displayError != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              displayError,
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
              onPressed: isListening ? null : _startListener,
              child: Text("Start".toUpperCase()),
            ),

            // Pause / Resume Btn
            if (state == StreamState.running)
              ElevatedButton(
                onPressed: _pauseListener,
                child: Text("Pause".toUpperCase()),
              )
            else if (state == StreamState.paused)
              ElevatedButton(
                onPressed: _resumeListener,
                child: Text("Resume".toUpperCase()),
              ),

            // Cancel Btn
            ElevatedButton(
              onPressed: isListening ? _cancelListener : null,
              child: Text("Cancel".toUpperCase()),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Educational disclaimer about pause vs cancel
        if (isListening)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "💡 Note: Pausing the Dart stream subscription buffers event delivery but does NOT stop native Android progress generation. Use 'Cancel' to stop native resources entirely.",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildBatteryDemo() {
    final int percentage = (_batteryLevel * 100).round();
    final IconData batteryIcon = _isBatteryCharging
        ? Icons.battery_charging_full
        : _batteryLevel >= 0.8
            ? Icons.battery_full
            : _batteryLevel >= 0.3
                ? Icons.battery_3_bar
                : Icons.battery_alert;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Icon(
          batteryIcon,
          size: 100,
          color: _isBatteryCharging
              ? Colors.green
              : _batteryLevel < 0.2
                  ? Colors.red
                  : Colors.blue,
        ),
        const SizedBox(height: 20),

        // State Status Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            "STATUS: ${_isBatteryListening ? 'SUBSCRIBED' : 'UNSUBSCRIBED'}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isBatteryListening ? Colors.green : Colors.blueGrey,
            ),
          ),
        ),
        const SizedBox(height: 25),

        // Progress bar for battery
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: LinearProgressIndicator(
            value: _batteryLevel,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6.0),
            backgroundColor: Colors.blue.shade50,
          ),
        ),
        const SizedBox(height: 10),

        Text(
          "Battery Level: $percentage%".toUpperCase(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          "Charging Status: ${_isBatteryCharging ? 'Charging' : 'Discharging'}".toUpperCase(),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 40),

        // Controls Panel
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            // Subscribe Button
            ElevatedButton(
              onPressed: _isBatteryListening ? null : _startBatteryListener,
              child: Text("Subscribe".toUpperCase()),
            ),

            // Unsubscribe Button
            ElevatedButton(
              onPressed: _isBatteryListening ? _cancelBatteryListener : null,
              child: Text("Unsubscribe".toUpperCase()),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Educational disclaimer about battery streaming
        if (_isBatteryListening)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "💡 Note: This demo uses a native BroadcastReceiver (Android) and NotificationCenter observers (iOS) to stream battery events efficiently only when changes occur.",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
