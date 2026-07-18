import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_channel/stream_lifecycle_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreamLifecycleController Tests', () {
    test('Triggers onPauseApp when app state becomes paused', () {
      bool pauseCalled = false;
      bool resumeCalled = false;

      final controller = StreamLifecycleController(
        onPauseApp: () => pauseCalled = true,
        onResumeApp: () => resumeCalled = true,
      );

      // Simulate app transitioning to background (paused)
      // ignore: invalid_use_of_protected_member
      ServicesBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(pauseCalled, isTrue);
      expect(resumeCalled, isFalse);

      controller.dispose();
    });

    test('Triggers onResumeApp when app state becomes resumed', () {
      bool pauseCalled = false;
      bool resumeCalled = false;

      final controller = StreamLifecycleController(
        onPauseApp: () => pauseCalled = true,
        onResumeApp: () => resumeCalled = true,
      );

      // First transition to paused to move out of the default resumed state
      // ignore: invalid_use_of_protected_member
      ServicesBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      pauseCalled = false; // Reset tracking variable

      // Transition to inactive first, then resumed (proper Flutter sequence)
      // ignore: invalid_use_of_protected_member
      ServicesBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      // ignore: invalid_use_of_protected_member
      ServicesBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(pauseCalled, isFalse);
      expect(resumeCalled, isTrue);

      controller.dispose();
    });
  });
}
