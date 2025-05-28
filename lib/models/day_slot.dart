class DaySlot {
  final String id;
  final String dayOfWeek;
  final DateTime startTime;
  final DateTime endTime;
  final int maxCapacity;
  final bool isActive;

  DaySlot({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
    required this.isActive,
  });

  factory DaySlot.fromJson(Map<String, dynamic> json) {
    return DaySlot(
      id: json['id'] as String,
      dayOfWeek: json['day_of_week'] as String,
      startTime: DateTime.parse('1970-01-01 ${json['time_slot']}'),
      endTime: DateTime.parse('1970-01-01 ${json['end_time']}'),
      maxCapacity: json['max_capacity'] as int,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_of_week': dayOfWeek,
      'time_slot': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
      'max_capacity': maxCapacity,
      'is_active': isActive,
    };
  }

  // Format start time for display (e.g., "7:30 AM")
  String get formattedStartTime {
    final hour = startTime.hour;
    final minute = startTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  // Format end time for display (e.g., "9:30 AM")
  String get formattedEndTime {
    final hour = endTime.hour;
    final minute = endTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  // Format time range for display (e.g., "7:30 AM - 9:30 AM")
  String get formattedTimeRange {
    return '$formattedStartTime - $formattedEndTime';
  }

  // Backward compatibility - use start time
  String get formattedTime => formattedStartTime;

  @override
  String toString() {
    return 'DaySlot(id: $id, dayOfWeek: $dayOfWeek, startTime: $startTime, endTime: $endTime, maxCapacity: $maxCapacity, isActive: $isActive)';
  }
}
