import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_event_channel/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Event Channel Integration Tests', () {
    const String channelName = 'com.chamelalaboratory.demo.flutter_event_channel/eventChannel';

    testWidgets('Verify basic stream connection and cancel flow', (WidgetTester tester) async {
      // Mock the binary messenger to make this integration test runnable in headless CLI environments
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall methodCall) async {
          return null; // Return success envelope
        },
      );

      // Start the application entry point
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify initial UI state is IDLE
      expect(find.text('STATUS: IDLE'), findsOneWidget);

      // 2. Tap START to initiate native stream connection
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      expect(find.text('STATUS: RUNNING'), findsOneWidget);

      // Construct and dispatch standard progress payload map via standard codec
      final eventData = const StandardMethodCodec().encodeSuccessEnvelope({
        'type': 'progress',
        'current': 10,
        'total': 100,
        'progress': 0.1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        channelName,
        eventData,
        null,
      );
      await tester.pumpAndSettle();

      // Verify the UI rendered the updated progress value
      expect(find.text('RECEIVED STREAM FROM NATIVE: 0.1'), findsOneWidget);

      // 3. Tap CANCEL to terminate subscription
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(find.text('STATUS: CANCELLED'), findsOneWidget);
    });
  });
}
