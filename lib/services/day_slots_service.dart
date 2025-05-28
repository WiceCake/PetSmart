import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/day_slot.dart';

class DaySlotsService {
  static final DaySlotsService _instance = DaySlotsService._internal();
  factory DaySlotsService() => _instance;
  DaySlotsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get day slots for a specific day of the week
  Future<List<DaySlot>> getDaySlots(String dayOfWeek) async {
    try {
      final response = await _supabase
          .from('day_slots')
          .select('*')
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true)
          .order('time_slot', ascending: true);

      return response.map<DaySlot>((json) => DaySlot.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch day slots: $e');
    }
  }

  /// Get all active day slots
  Future<List<DaySlot>> getAllDaySlots() async {
    try {
      final response = await _supabase
          .from('day_slots')
          .select('*')
          .eq('is_active', true)
          .order('day_of_week, time_slot', ascending: true);

      return response.map<DaySlot>((json) => DaySlot.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all day slots: $e');
    }
  }

  /// Get available slots for a specific date
  /// This will check against existing appointments to calculate availability
  Future<List<DaySlotAvailability>> getAvailableSlots(DateTime date) async {
    try {
      final dayOfWeek = _getDayOfWeekName(date);

      // Get day slots for the specific day
      final daySlots = await getDaySlots(dayOfWeek);

      // Get appointment counts for each time slot on this date
      final dateStr = date.toIso8601String().split('T')[0];
      final appointmentCounts = <String, int>{};

      for (final slot in daySlots) {
        final timeStr = '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}:00';

        final response = await _supabase
            .from('appointments')
            .select('id, appointment_time, status')
            .eq('appointment_date', dateStr)
            .eq('appointment_time', timeStr)
            .neq('status', 'Cancelled')
            .neq('status', 'Expired');

        // Count only active (non-expired) appointments
        int activeCount = 0;
        for (final appointment in response) {
          if (_isAppointmentActive(appointment, date)) {
            activeCount++;
          }
        }

        appointmentCounts[timeStr] = activeCount;
      }

      // Calculate available capacity for each slot
      return daySlots.map((slot) {
        final timeStr = '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}:00';
        final bookedCount = appointmentCounts[timeStr] ?? 0;
        final availableCapacity = (slot.maxCapacity - bookedCount).clamp(0, slot.maxCapacity);

        return DaySlotAvailability(
          daySlot: slot,
          availableCapacity: availableCapacity,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch available slots: $e');
    }
  }

  /// Check if a specific day has any available slots
  Future<bool> hasAvailableSlots(DateTime date) async {
    try {
      final availableSlots = await getAvailableSlots(date);
      return availableSlots.any((slot) => slot.availableCapacity > 0);
    } catch (e) {
      return false;
    }
  }

  /// Get day of week name from DateTime
  String _getDayOfWeekName(DateTime date) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return dayNames[date.weekday - 1];
  }

  /// Check if a day is a working day (has slots)
  bool isWorkingDay(DateTime date) {
    final dayOfWeek = _getDayOfWeekName(date);
    return dayOfWeek != 'Sunday'; // Sunday is closed
  }

  /// Helper method to check if an appointment is still active (not expired)
  bool _isAppointmentActive(Map<String, dynamic> appointment, DateTime appointmentDate) {
    try {
      final status = appointment['status']?.toString() ?? '';

      // If it's not pending, check the status
      if (status != 'Pending') {
        return status == 'Completed'; // Only completed appointments count as "had an appointment"
      }

      // For pending appointments, check if they've expired
      final appointmentTimeStr = appointment['appointment_time']?.toString() ?? '';
      if (appointmentTimeStr.isEmpty) return true; // Assume active if no time

      // Parse the time string (format: HH:mm:ss)
      final timeParts = appointmentTimeStr.split(':');
      if (timeParts.length < 2) return true; // Assume active if invalid time

      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;

      // Combine date and time
      final appointmentDateTime = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        hour,
        minute,
      );

      // Check if appointment is still in the future (not expired)
      return DateTime.now().isBefore(appointmentDateTime);
    } catch (e) {
      return true; // Assume active on error to be safe
    }
  }
}

/// Class to represent a day slot with its current availability
class DaySlotAvailability {
  final DaySlot daySlot;
  final int availableCapacity;

  DaySlotAvailability({
    required this.daySlot,
    required this.availableCapacity,
  });

  bool get isAvailable => availableCapacity > 0;

  String get availabilityText {
    if (availableCapacity == 0) {
      return 'Full';
    } else if (availableCapacity == 1) {
      return '1 slot left';
    } else {
      return '$availableCapacity slots left';
    }
  }
}
