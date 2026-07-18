import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_channel/progress_event.dart';

void main() {
  group('ProgressEvent Tests', () {
    test('Successful parsing of valid payload', () {
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

    test('Throws FormatException on invalid field types', () {
      final map = {
        'type': 'progress',
        'current': 'five', // should be int
        'total': 100,
        'progress': 0.05,
        'timestamp': 1600000000000,
      };

      expect(() => ProgressEvent.fromMap(map), throwsFormatException);
    });
  });
}
