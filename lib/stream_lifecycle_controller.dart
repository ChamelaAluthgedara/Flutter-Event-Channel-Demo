import 'package:flutter/widgets.dart';

/// A controller that monitors application lifecycle events using the modern
/// [AppLifecycleListener] API and triggers policy-based callbacks.
class StreamLifecycleController {
  final VoidCallback onPauseApp;
  final VoidCallback onResumeApp;
  late final AppLifecycleListener _listener;

  StreamLifecycleController({
    required this.onPauseApp,
    required this.onResumeApp,
  }) {
    _listener = AppLifecycleListener(
      onStateChange: _handleStateChange,
    );
  }

  void _handleStateChange(AppLifecycleState state) {
    debugPrint("AppLifecycleState changed to: $state");
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Trigger policy callback to stop background processing
        onPauseApp();
        break;
      case AppLifecycleState.resumed:
        // Trigger policy callback to resume processing when returning to foreground
        onResumeApp();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Logged and documented behaviors
        break;
    }
  }

  /// Cleans up the lifecycle listener resources.
  void dispose() {
    _listener.dispose();
  }
}
