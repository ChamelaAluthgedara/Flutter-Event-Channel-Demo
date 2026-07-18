import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_channel/progress_stream_controller.dart';

void main() {
  group('ProgressStreamController Tests', () {
    late StreamController<dynamic> mockStreamController;
    late ProgressStreamController controller;
    late int updateCount;

    setUp(() {
      mockStreamController = StreamController<dynamic>.broadcast();
      updateCount = 0;
      controller = ProgressStreamController(
        onUpdate: () => updateCount++,
        streamFactory: (args) => mockStreamController.stream,
      );
    });

    tearDown(() {
      controller.dispose();
      mockStreamController.close();
    });

    test('Initial state is idle', () {
      expect(controller.state, StreamState.idle);
      expect(controller.progress, 0.0);
      expect(controller.isListening, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('Start subscription transitions state and notifies listeners', () {
      controller.start(intervalMs: 200, totalCount: 10, shouldSimulateError: false);

      expect(controller.state, StreamState.running);
      expect(controller.isListening, isTrue);
      expect(updateCount, 1);
    });

    test('Duplicate start calls are ignored and do not start multiple streams', () {
      controller.start(intervalMs: 200, totalCount: 10, shouldSimulateError: false);
      expect(updateCount, 1);

      controller.start(intervalMs: 200, totalCount: 10, shouldSimulateError: false);
      expect(updateCount, 1); // should still be 1 (ignored)
    });

    test('Receiving valid event updates progress and notifies', () async {
      controller.start(intervalMs: 200, totalCount: 10, shouldSimulateError: false);
      
      mockStreamController.add({
        'type': 'progress',
        'current': 5,
        'total': 10,
        'progress': 0.5,
        'timestamp': 1600000000000,
      });

      await Future.delayed(Duration.zero); // yield event loop

      expect(controller.progress, 0.5);
      expect(updateCount, 2); // 1 for start, 1 for event
    });

    test('Receiving error transitions state and sets error message', () async {
      controller.start(intervalMs: 200, totalCount: 10, shouldSimulateError: false);

      mockStreamController.addError(
        PlatformException(
          code: 'TEST_ERROR',
          message: 'An error occurred',
          details: 'Error details',
        ),
      );

      await Future.delayed(Duration.zero);

      expect(controller.state, StreamState.error);
      expect(controller.progress, 0.0);
      expect(controller.errorMessage, 'An error occurred (Error details)');
      expect(controller.isListening, isFalse);
    });

    test('Done event transitions state to completed', () async {
      controller.start(intervalMs: 200, totalCount: 10, shouldSimulateError: false);

      await mockStreamController.close();
      await Future.delayed(Duration.zero);

      expect(controller.state, StreamState.completed);
      expect(controller.isListening, isFalse);
    });

    test('Pause and resume operations work correctly', () {
      controller.start(intervalMs: 200, totalCount: 10, shouldSimulateError: false);

      controller.pause();
      expect(controller.state, StreamState.paused);
      expect(updateCount, 2); // start, pause

      controller.resume();
      expect(controller.state, StreamState.running);
      expect(updateCount, 3); // start, pause, resume
    });

    test('Cancel terminates subscription and resets status', () {
      controller.start(intervalMs: 200, totalCount: 10, shouldSimulateError: false);

      controller.cancel();
      expect(controller.state, StreamState.cancelled);
      expect(controller.isListening, isFalse);
      expect(controller.progress, 0.0);
    });

    test('Disposed controller does not receive events or trigger notifications', () async {
      controller.start(intervalMs: 200, totalCount: 10, shouldSimulateError: false);
      expect(updateCount, 1);

      controller.dispose();
      expect(controller.isDisposed, isTrue);

      mockStreamController.add({
        'type': 'progress',
        'current': 5,
        'total': 10,
        'progress': 0.5,
        'timestamp': 1600000000000,
      });

      await Future.delayed(Duration.zero);

      // Verify no update count increase and no progress change happened after disposal
      expect(controller.progress, 0.0);
      expect(updateCount, 1);
    });
  });
}
