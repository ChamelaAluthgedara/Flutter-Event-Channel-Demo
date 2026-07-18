import 'dart:async';
import 'package:flutter/services.dart';

import 'progress_event.dart';

/// The various operational states of the EventChannel subscription.
enum StreamState { idle, running, paused, completed, cancelled, error }

/// A type definition for injecting stream factories in tests.
typedef StreamFactory = Stream<dynamic> Function(Map<String, dynamic> arguments);

/// A controller that encapsulates progress EventChannel listening and state management.
class ProgressStreamController {
  final StreamFactory _streamFactory;
  final void Function() _onUpdate;

  StreamSubscription<dynamic>? _subscription;
  double _progress = 0.0;
  String? _errorMessage;
  StreamState _state = StreamState.idle;
  bool _isDisposed = false;

  ProgressStreamController({
    required void Function() onUpdate,
    StreamFactory? streamFactory,
  })  : _onUpdate = onUpdate,
        _streamFactory = streamFactory ??
            ((args) => const EventChannel(
                  'com.chamelalaboratory.demo.flutter_event_channel/eventChannel',
                ).receiveBroadcastStream(args));

  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  StreamState get state => _state;
  bool get isListening => _subscription != null;
  bool get isDisposed => _isDisposed;

  /// Starts listening to the native progress events.
  void start({
    required int intervalMs,
    required int totalCount,
    required bool shouldSimulateError,
  }) {
    if (_isDisposed) return;
    if (isListening) return; // Prevent duplicate starts

    _progress = 0.0;
    _errorMessage = null;
    _state = StreamState.running;
    _notify();

    _subscription = _streamFactory({
      'updateIntervalMs': intervalMs,
      'totalCount': totalCount,
      'shouldSimulateError': shouldSimulateError,
    }).listen(
      _handleEvent,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  /// Cancels the subscription and resets status.
  void cancel() {
    if (_isDisposed) return;
    _subscription?.cancel();
    _subscription = null;
    _progress = 0.0;
    _state = StreamState.cancelled;
    _notify();
  }

  /// Pauses the delivery of stream events.
  void pause() {
    if (_isDisposed) return;
    if (_state == StreamState.running) {
      _subscription?.pause();
      _state = StreamState.paused;
      _notify();
    }
  }

  /// Resumes the delivery of paused stream events.
  void resume() {
    if (_isDisposed) return;
    if (_state == StreamState.paused) {
      _subscription?.resume();
      _state = StreamState.running;
      _notify();
    }
  }

  void _handleEvent(dynamic value) {
    if (_isDisposed) return;
    if (value is! Map) return;

    try {
      final event = ProgressEvent.fromMap(value);
      _progress = event.progress.clamp(0.0, 1.0);
      _notify();
    } catch (e) {
      // Handle malformed maps silently
    }
  }

  void _handleError(Object error) {
    if (_isDisposed) return;
    if (error is PlatformException) {
      _errorMessage = "${error.message} (${error.details})";
    } else {
      _errorMessage = error.toString();
    }
    _subscription = null;
    _progress = 0.0;
    _state = StreamState.error;
    _notify();
  }

  void _handleDone() {
    if (_isDisposed) return;
    _subscription?.cancel();
    _subscription = null;
    _state = StreamState.completed;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) {
      _onUpdate();
    }
  }

  /// Clears subscriptions and prevents any future state notifications.
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _subscription = null;
  }
}
