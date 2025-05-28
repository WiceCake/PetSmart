import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new appointment
  Future<Map<String, dynamic>?> createAppointment({
    required String petId,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? daySlotId,
    String status = 'Pending',
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare appointment data with explicit column names
      final appointmentData = <String, dynamic>{
        'user_id': user.id,
        'pet_id': petId,
        'appointment_date': appointmentDate.toIso8601String().split('T')[0],
        'appointment_time': appointmentTime,
        'status': status,
      };

      // Add day_slot_id if provided - this is critical for time range display
      if (daySlotId != null && daySlotId.isNotEmpty) {
        appointmentData['day_slot_id'] = daySlotId;
      }

      print('Creating appointment with data: $appointmentData');

      // Use a more robust insert approach
      final response = await _supabase
          .from('appointments')
          .insert(appointmentData)
          .select('*')
          .single();

      print('Appointment created successfully: $response');
      return response;
    } catch (e) {
      print('Failed to create appointment: $e');
      throw Exception('Failed to create appointment: $e');
    }
  }

  /// Get all appointments for the current user with day slot information
  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            pets(name),
            day_slots(
              day_of_week,
              time_slot,
              end_time
            )
          ''')
          .eq('user_id', user.id)
          .order('appointment_date', ascending: false)
          .order('appointment_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch appointments: $e');
    }
  }

  /// Get upcoming appointments with day slot information
  Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // Get pending appointments from today onwards - let client handle expiration logic
      final today = DateTime.now().toIso8601String().split('T')[0];

      final appointments = await _supabase
          .from('appointments')
          .select('*')
          .eq('user_id', user.id)
          .eq('status', 'Pending')
          .gte('appointment_date', today)
          .order('appointment_date', ascending: true)
          .order('appointment_time', ascending: true);

      // Manually fetch related data for each appointment
      final enrichedAppointments = <Map<String, dynamic>>[];

      for (final appointment in appointments) {
        final enrichedAppointment = Map<String, dynamic>.from(appointment);

        // Fetch pet information
        if (appointment['pet_id'] != null) {
          try {
            final pet = await _supabase
                .from('pets')
                .select('name')
                .eq('id', appointment['pet_id'])
                .single();
            enrichedAppointment['pets'] = pet;
          } catch (e) {
            enrichedAppointment['pets'] = {'name': 'Unknown Pet'};
          }
        }

        // Fetch day slot information
        if (appointment['day_slot_id'] != null) {
          try {
            final daySlot = await _supabase
                .from('day_slots')
                .select('day_of_week, time_slot, end_time')
                .eq('id', appointment['day_slot_id'])
                .single();
            enrichedAppointment['day_slots'] = daySlot;
          } catch (e) {
            enrichedAppointment['day_slots'] = null;
          }
        }

        enrichedAppointments.add(enrichedAppointment);
      }

      return enrichedAppointments;
    } catch (e) {
      throw Exception('Failed to fetch upcoming appointments: $e');
    }
  }

  /// Get past appointments with day slot information
  Future<List<Map<String, dynamic>>> getPastAppointments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // Get completed, cancelled, and expired appointments
      final appointments = await _supabase
          .from('appointments')
          .select('*')
          .eq('user_id', user.id)
          .or('status.eq.Completed,status.eq.Cancelled,status.eq.Expired')
          .order('appointment_date', ascending: false)
          .order('appointment_time', ascending: false);

      // Manually fetch related data for each appointment
      final enrichedAppointments = <Map<String, dynamic>>[];

      for (final appointment in appointments) {
        final enrichedAppointment = Map<String, dynamic>.from(appointment);

        // Fetch pet information
        if (appointment['pet_id'] != null) {
          try {
            final pet = await _supabase
                .from('pets')
                .select('name')
                .eq('id', appointment['pet_id'])
                .single();
            enrichedAppointment['pets'] = pet;
          } catch (e) {
            enrichedAppointment['pets'] = {'name': 'Unknown Pet'};
          }
        }

        // Fetch day slot information
        if (appointment['day_slot_id'] != null) {
          try {
            final daySlot = await _supabase
                .from('day_slots')
                .select('day_of_week, time_slot, end_time')
                .eq('id', appointment['day_slot_id'])
                .single();
            enrichedAppointment['day_slots'] = daySlot;
          } catch (e) {
            enrichedAppointment['day_slots'] = null;
          }
        }

        enrichedAppointments.add(enrichedAppointment);
      }

      return enrichedAppointments;
    } catch (e) {
      throw Exception('Failed to fetch past appointments: $e');
    }
  }

  /// Cancel an appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update appointment status to 'Cancelled' (updated_at will be set automatically by trigger)
      final response = await _supabase
          .from('appointments')
          .update({'status': 'Cancelled'})
          .eq('id', appointmentId)
          .eq('user_id', user.id)
          .select();

      if (response.isEmpty) {
        throw Exception('Appointment not found or you do not have permission to cancel it');
      }

      print('Appointment cancelled successfully: ${response.first['id']}');
    } catch (e) {
      print('Error cancelling appointment: $e');
      rethrow;
    }
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  /// Check if a pet already has an active appointment on a specific date
  /// Active means: not cancelled, not expired, and not past its scheduled time
  Future<bool> hasPetAppointmentOnDate(String petId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('appointments')
          .select('id, appointment_time, status')
          .eq('pet_id', petId)
          .eq('appointment_date', dateStr)
          .neq('status', 'Cancelled')
          .neq('status', 'Expired');

      if (response.isEmpty) {
        return false;
      }

      // Check if any of the appointments are still active (not expired)
      for (final appointment in response) {
        if (_isAppointmentActive(appointment, date)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
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

  /// Check if a time slot is available for a specific date
  Future<bool> isTimeSlotAvailable(DateTime date, String timeSlot) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('appointments')
          .select('id, appointment_time, status')
          .eq('appointment_date', dateStr)
          .eq('appointment_time', timeSlot)
          .neq('status', 'Cancelled')
          .neq('status', 'Expired');

      // Count only active (non-expired) appointments
      int activeCount = 0;
      for (final appointment in response) {
        if (_isAppointmentActive(appointment, date)) {
          activeCount++;
        }
      }

      // Assume max 3 appointments per time slot
      return activeCount < 3;
    } catch (e) {
      return false;
    }
  }

  /// Get active appointment count for a specific date and time slot
  Future<int> getAppointmentCount(DateTime date, String timeSlot) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('appointments')
          .select('id, appointment_time, status')
          .eq('appointment_date', dateStr)
          .eq('appointment_time', timeSlot)
          .neq('status', 'Cancelled')
          .neq('status', 'Expired');

      // Count only active (non-expired) appointments
      int activeCount = 0;
      for (final appointment in response) {
        if (_isAppointmentActive(appointment, date)) {
          activeCount++;
        }
      }

      return activeCount;
    } catch (e) {
      return 0;
    }
  }
}
