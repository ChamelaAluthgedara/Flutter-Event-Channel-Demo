import 'package:flutter/foundation.dart';

/// A typed, immutable model representing a progress event received from the native host.
@immutable
class ProgressEvent {
  final String type;
  final int current;
  final int total;
  final double progress;
  final int timestamp;

  const ProgressEvent({
    required this.type,
    required this.current,
    required this.total,
    required this.progress,
    required this.timestamp,
  });

  /// Factory method to safely parse a Map payload from the native platform.
  /// Throws [FormatException] if validation fails or fields are missing/incorrect.
  factory ProgressEvent.fromMap(Map<dynamic, dynamic> map) {
    if (!map.containsKey('type') ||
        !map.containsKey('current') ||
        !map.containsKey('total') ||
        !map.containsKey('progress') ||
        !map.containsKey('timestamp')) {
      throw const FormatException("Missing required event payload fields.");
    }

    final type = map['type'];
    final current = map['current'];
    final total = map['total'];
    final progress = map['progress'];
    final timestamp = map['timestamp'];

    if (type is! String ||
        current is! int ||
        total is! int ||
        progress is! double ||
        timestamp is! int) {
      throw const FormatException("Invalid field type in event payload.");
    }

    return ProgressEvent(
      type: type,
      current: current,
      total: total,
      progress: progress,
      timestamp: timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          current == other.current &&
          total == other.total &&
          progress == other.progress &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      type.hashCode ^
      current.hashCode ^
      total.hashCode ^
      progress.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'ProgressEvent(type: $type, current: $current, total: $total, progress: $progress, timestamp: $timestamp)';
  }
}
