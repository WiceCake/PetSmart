import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/services/notification_helper.dart';
import 'package:intl/intl.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for real-time updates
  final StreamController<List<Map<String, dynamic>>> _upcomingAppointmentsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _pastAppointmentsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _allAppointmentsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Subscriptions for cleanup
  RealtimeChannel? _appointmentsSubscription;

  /// Get upcoming appointments stream for real-time updates
  Stream<List<Map<String, dynamic>>> get upcomingAppointmentsStream => _upcomingAppointmentsController.stream;

  /// Get past appointments stream for real-time updates
  Stream<List<Map<String, dynamic>>> get pastAppointmentsStream => _pastAppointmentsController.stream;

  /// Get all appointments stream for real-time updates
  Stream<List<Map<String, dynamic>>> get allAppointmentsStream => _allAppointmentsController.stream;

  /// Initialize real-time subscriptions for appointments
  Future<void> initializeRealtimeSubscriptions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('AppointmentService: User not authenticated, skipping real-time initialization');
      return;
    }

    debugPrint('AppointmentService: Initializing real-time subscriptions for user: ${user.id}');

    try {
      await _setupRealtimeSubscriptions();
      debugPrint('AppointmentService: Real-time subscriptions initialized successfully');
    } catch (e) {
      debugPrint('AppointmentService: Error initializing real-time subscriptions: $e');
    }
  }

  /// Setup real-time subscriptions for appointments
  Future<void> _setupRealtimeSubscriptions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Unsubscribe from previous subscription
    await _appointmentsSubscription?.unsubscribe();

    // Subscribe to appointments changes for current user
    _appointmentsSubscription = _supabase
        .channel('appointments:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleAppointmentChange(payload),
        )
        .subscribe();

    debugPrint('AppointmentService: Subscribed to appointments changes for user $userId');
  }

  /// Handle appointment changes from real-time subscription
  void _handleAppointmentChange(PostgresChangePayload payload) {
    debugPrint('AppointmentService: Appointment change detected: ${payload.eventType}');
    debugPrint('AppointmentService: Payload details - oldRecord: ${payload.oldRecord}, newRecord: ${payload.newRecord}');

    // Refresh all appointment-related data when any appointment changes
    refreshAppointmentData();
  }

  /// Refresh all appointment-related data and emit to streams
  Future<void> refreshAppointmentData() async {
    debugPrint('AppointmentService: Refreshing appointment data due to real-time change');

    try {
      // Add a small delay to ensure database consistency
      await Future.delayed(const Duration(milliseconds: 100));

      // Refresh upcoming, past, and all appointments in parallel
      await Future.wait([
        _loadAndEmitUpcomingAppointments(),
        _loadAndEmitPastAppointments(),
        _loadAndEmitAllAppointments(),
      ]);

      debugPrint('AppointmentService: Appointment data refreshed successfully');
    } catch (e) {
      debugPrint('AppointmentService: Error refreshing appointment data: $e');
    }
  }

  /// Load upcoming appointments and emit to stream
  Future<void> _loadAndEmitUpcomingAppointments() async {
    try {
      final appointments = await getUpcomingAppointments();
      if (!_upcomingAppointmentsController.isClosed) {
        _upcomingAppointmentsController.add(appointments);
        debugPrint('AppointmentService: Emitted ${appointments.length} upcoming appointments to stream');
      }
    } catch (e) {
      debugPrint('AppointmentService: Error loading upcoming appointments for stream: $e');
      if (!_upcomingAppointmentsController.isClosed) {
        _upcomingAppointmentsController.addError(e);
      }
    }
  }

  /// Load past appointments and emit to stream
  Future<void> _loadAndEmitPastAppointments() async {
    try {
      final appointments = await getPastAppointments();
      if (!_pastAppointmentsController.isClosed) {
        _pastAppointmentsController.add(appointments);
        debugPrint('AppointmentService: Emitted ${appointments.length} past appointments to stream');
      }
    } catch (e) {
      debugPrint('AppointmentService: Error loading past appointments for stream: $e');
      if (!_pastAppointmentsController.isClosed) {
        _pastAppointmentsController.addError(e);
      }
    }
  }

  /// Load all appointments and emit to stream
  Future<void> _loadAndEmitAllAppointments() async {
    try {
      final appointments = await getUserAppointments();
      if (!_allAppointmentsController.isClosed) {
        _allAppointmentsController.add(appointments);
        debugPrint('AppointmentService: Emitted ${appointments.length} total appointments to stream');
      }
    } catch (e) {
      debugPrint('AppointmentService: Error loading all appointments for stream: $e');
      if (!_allAppointmentsController.isClosed) {
        _allAppointmentsController.addError(e);
      }
    }
  }

  /// Dispose of resources and subscriptions
  Future<void> dispose() async {
    debugPrint('AppointmentService: Disposing resources...');

    // Unsubscribe from real-time subscriptions
    await _appointmentsSubscription?.unsubscribe();

    // Close stream controllers
    await _upcomingAppointmentsController.close();
    await _pastAppointmentsController.close();
    await _allAppointmentsController.close();

    debugPrint('AppointmentService: Disposed successfully');
  }

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

      // Log appointment creation in production-ready way
      debugPrint('Creating appointment with data: $appointmentData');

      // Use a more robust insert approach
      final response = await _supabase
          .from('appointments')
          .insert(appointmentData)
          .select('*')
          .single();

      debugPrint('Appointment created successfully: $response');

      // Send notification for appointment confirmation
      try {
        // Get pet name for notification
        final pet = await _supabase
            .from('pets')
            .select('name')
            .eq('id', petId)
            .single();

        final petName = pet['name'] ?? 'Your pet';
        final formattedDate = DateFormat('MMM dd, yyyy').format(appointmentDate);
        final formattedTime = appointmentTime;

        await NotificationHelper.notifyAppointmentConfirmed(
          appointmentId: response['id'],
          petName: petName,
          appointmentDate: formattedDate,
          appointmentTime: formattedTime,
        );
      } catch (notificationError) {
        debugPrint('Failed to send appointment notification: $notificationError');
        // Don't fail the appointment creation if notification fails
      }

      return response;
    } catch (e) {
      debugPrint('Failed to create appointment: $e');
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

      debugPrint('Appointment cancelled successfully: ${response.first['id']}');

      // Send notification for appointment cancellation
      try {
        final appointment = response.first;

        // Get pet name for notification
        final pet = await _supabase
            .from('pets')
            .select('name')
            .eq('id', appointment['pet_id'])
            .single();

        final petName = pet['name'] ?? 'Your pet';
        final appointmentDate = DateTime.parse(appointment['appointment_date']);
        final formattedDate = DateFormat('MMM dd, yyyy').format(appointmentDate);

        await NotificationHelper.notifyAppointmentCancelled(
          appointmentId: appointmentId,
          petName: petName,
          appointmentDate: formattedDate,
        );
      } catch (notificationError) {
        debugPrint('Failed to send cancellation notification: $notificationError');
        // Don't fail the cancellation if notification fails
      }
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
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
