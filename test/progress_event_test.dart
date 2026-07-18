import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_channel/progress_event.dart';

void main() {
  group('ProgressEvent Tests', () {
    test('Successful parsing of valid payload (no optional fields)', () {
      final map = {
        'type': 'progress',
        'current': 5,
        'total': 100,
        'progress': 0.05,
        'timestamp': 1600000000000,
      };

      final event = ProgressEvent.fromMap(map);

      expect(event.type, 'progress');
      expect(event.current, 5);
      expect(event.total, 100);
      expect(event.progress, 0.05);
      expect(event.timestamp, 1600000000000);
      expect(event.status, isNull);
    });

    test('Successful parsing of valid payload with optional status field', () {
      final map = {
        'type': 'progress',
        'current': 5,
        'total': 100,
        'progress': 0.05,
        'timestamp': 1600000000000,
        'status': 'in_progress',
      };

      final event = ProgressEvent.fromMap(map);

      expect(event.status, 'in_progress');
    });

    test('Throws FormatException on missing fields', () {
      final map = {
        'type': 'progress',
        'current': 5,
        'total': 100,
        // 'progress' is missing
        'timestamp': 1600000000000,
      };

      expect(() => ProgressEvent.fromMap(map), throwsFormatException);
    });

    test('Throws FormatException on incorrect field types', () {
      final map = {
        'type': 'progress',
        'current': 'five', // should be int
        'total': 100,
        'progress': 0.05,
        'timestamp': 1600000000000,
      };

      expect(() => ProgressEvent.fromMap(map), throwsFormatException);
    });

    test('Throws FormatException when progress is below zero', () {
      final map = {
        'type': 'progress',
        'current': 5,
        'total': 100,
        'progress': -0.01, // below zero
        'timestamp': 1600000000000,
      };

      expect(() => ProgressEvent.fromMap(map), throwsFormatException);
    });

    test('Throws FormatException when progress is above one', () {
      final map = {
        'type': 'progress',
        'current': 5,
        'total': 100,
        'progress': 1.01, // above one
        'timestamp': 1600000000000,
      };

      expect(() => ProgressEvent.fromMap(map), throwsFormatException);
    });

    test('Throws FormatException when event type is unknown', () {
      final map = {
        'type': 'unknown_type', // unknown type
        'current': 5,
        'total': 100,
        'progress': 0.05,
        'timestamp': 1600000000000,
      };

      expect(() => ProgressEvent.fromMap(map), throwsFormatException);
    });

    test('Throws FormatException when optional field type is invalid', () {
      final map = {
        'type': 'progress',
        'current': 5,
        'total': 100,
        'progress': 0.05,
        'timestamp': 1600000000000,
        'status': 123, // should be String
      };

      expect(() => ProgressEvent.fromMap(map), throwsFormatException);
    });

    test('Value equality and hashcode equivalence checks', () {
      const event1 = ProgressEvent(
        type: 'progress',
        current: 10,
        total: 100,
        progress: 0.1,
        timestamp: 1600000000000,
        status: 'active',
      );

      const event2 = ProgressEvent(
        type: 'progress',
        current: 10,
        total: 100,
        progress: 0.1,
        timestamp: 1600000000000,
        status: 'active',
      );

      const event3 = ProgressEvent(
        type: 'progress',
        current: 11, // different value
        total: 100,
        progress: 0.11,
        timestamp: 1600000000000,
        status: 'active',
      );

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));

      expect(event1, isNot(equals(event3)));
      expect(event1.hashCode, isNot(equals(event3.hashCode)));
    });
  });
}
