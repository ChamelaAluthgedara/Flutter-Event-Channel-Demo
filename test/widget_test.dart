import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_channel/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String channelName = 'com.chamelalaboratory.demo.flutter_event_channel/eventChannel';

  group('Event Channel Widget Tests', () {
    testWidgets('Initial UI state is correct', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Verify initial texts
      expect(find.text('START'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('STATUS: IDLE'), findsOneWidget);
      expect(find.text('RECEIVED STREAM FROM NATIVE: 0.0'), findsOneWidget);

      // Verify progress indicator presence
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final LinearProgressIndicator indicator = tester.widget(find.byType(LinearProgressIndicator));
      expect(indicator.value, 0.0);
    });

    testWidgets('Starts listener and handles progress events', (WidgetTester tester) async {
      final List<MethodCall> log = <MethodCall>[];

      // Register a mock handler to intercept listen/cancel signals
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null; // return success
        },
      );

      await tester.pumpWidget(const MyApp());

      // Tap the Start button
      await tester.tap(find.text('START'));
      await tester.pump();

      expect(log.length, 1);
      expect(log.first.method, 'listen');
      expect(find.text('STATUS: RUNNING'), findsOneWidget);

      // Simulate a progress event map encoded using StandardMethodCodec success envelope
      final ByteData eventData = const StandardMethodCodec().encodeSuccessEnvelope({
        'type': 'progress',
        'current': 50,
        'total': 100,
        'progress': 0.50,
        'timestamp': 1600000000000,
      });

      // Deliver platform message to the EventChannel
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        channelName,
        eventData,
        null,
      );
      await tester.pump();

      // Verify progress updates in text and indicator
      expect(find.text('RECEIVED STREAM FROM NATIVE: 0.5'), findsOneWidget);
      final LinearProgressIndicator indicator = tester.widget(find.byType(LinearProgressIndicator));
      expect(indicator.value, 0.5);
    });

    testWidgets('Handles native error and displays it in UI', (WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall methodCall) async {
          return null;
        },
      );

      await tester.pumpWidget(const MyApp());

      // Tap start button
      await tester.tap(find.text('START'));
      await tester.pump();

      // Encode a native simulated error envelope
      final ByteData errorData = const StandardMethodCodec().encodeErrorEnvelope(
        code: 'SIMULATED_ERROR',
        message: 'Simulated native failure occurred.',
        details: {
          'current': 50,
          'total': 100,
          'timestamp': 1600000000000,
          'description': 'Demonstration of a simulated native stream failure.',
        },
      );

      // Deliver error message
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        channelName,
        errorData,
        null,
      );
      await tester.pump();

      // Assert error message is displayed
      expect(
        find.text('Simulated native failure occurred. ({current: 50, total: 100, timestamp: 1600000000000, description: Demonstration of a simulated native stream failure.})'),
        findsOneWidget,
      );
      expect(find.text('STATUS: ERROR'), findsOneWidget);

      // Value resets to 0.0
      final LinearProgressIndicator indicator = tester.widget(find.byType(LinearProgressIndicator));
      expect(indicator.value, 0.0);
    });

    testWidgets('Handles pause and resume transitions', (WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall methodCall) async {
          return null;
        },
      );

      await tester.pumpWidget(const MyApp());

      expect(find.text('STATUS: IDLE'), findsOneWidget);

      // Tap Start
      await tester.tap(find.text('START'));
      await tester.pump();
      expect(find.text('STATUS: RUNNING'), findsOneWidget);

      // Tap Pause
      await tester.tap(find.text('PAUSE'));
      await tester.pump();
      expect(find.text('STATUS: PAUSED'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('RESUME'));
      await tester.pump();
      expect(find.text('STATUS: RUNNING'), findsOneWidget);
    });

    testWidgets('Ensures cancellation works from running and paused states', (WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall methodCall) async {
          return null;
        },
      );

      await tester.pumpWidget(const MyApp());

      // 1. Cancel from Running
      await tester.tap(find.text('START'));
      await tester.pump();
      expect(find.text('STATUS: RUNNING'), findsOneWidget);

      await tester.tap(find.text('CANCEL'));
      await tester.pump();
      expect(find.text('STATUS: CANCELLED'), findsOneWidget);

      // 2. Cancel from Paused
      await tester.tap(find.text('START'));
      await tester.pump();
      await tester.tap(find.text('PAUSE'));
      await tester.pump();
      expect(find.text('STATUS: PAUSED'), findsOneWidget);

      await tester.tap(find.text('CANCEL'));
      await tester.pump();
      expect(find.text('STATUS: CANCELLED'), findsOneWidget);
    });
  });
}
