import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_smart/pages/appointment/appointment.dart';
import 'package:pet_smart/services/appointment_service.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background
const Color primaryGreen = Color(0xFF4CAF50);  // Success green

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _pastAppointments = [];
  bool _isLoading = true;
  String? _error;
  String? _cancellingAppointmentId; // Track which appointment is being cancelled

  // Stream subscriptions for real-time updates
  StreamSubscription<List<Map<String, dynamic>>>? _upcomingSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _pastSubscription;

  // Real-time update indicators
  bool _isRealtimeConnected = false;
  bool _hasRealtimeError = false;

  /// Check if an appointment is expired (past its scheduled date and time)
  bool _isAppointmentExpired(Map<String, dynamic> appointment) {
    try {
      final appointmentDate = DateTime.parse(appointment['appointment_date']);
      final appointmentTimeStr = appointment['appointment_time']?.toString() ?? '';

      if (appointmentTimeStr.isEmpty) return false;

      // Parse the time string (format: HH:mm:ss)
      final timeParts = appointmentTimeStr.split(':');
      if (timeParts.length < 2) return false;

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

      // Check if appointment is in the past
      return DateTime.now().isAfter(appointmentDateTime);
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeRealtimeAndLoadData();
  }

  /// Initialize real-time subscriptions and load initial data
  Future<void> _initializeRealtimeAndLoadData() async {
    try {
      // Initialize real-time subscriptions
      await _appointmentService.initializeRealtimeSubscriptions();

      // Set up stream listeners
      _setupStreamListeners();

      // Load initial data
      await _loadAppointments();

      setState(() {
        _isRealtimeConnected = true;
        _hasRealtimeError = false;
      });
    } catch (e) {
      debugPrint('AppointmentListScreen: Error initializing real-time: $e');
      setState(() {
        _hasRealtimeError = true;
        _isRealtimeConnected = false;
      });

      // Fallback to manual loading
      await _loadAppointments();
    }
  }

  /// Setup stream listeners for real-time updates
  void _setupStreamListeners() {
    // Listen to upcoming appointments stream
    _upcomingSubscription = _appointmentService.upcomingAppointmentsStream.listen(
      (appointments) {
        debugPrint('AppointmentListScreen: Received ${appointments.length} upcoming appointments from stream');
        _processUpcomingAppointments(appointments);
      },
      onError: (error) {
        debugPrint('AppointmentListScreen: Error in upcoming appointments stream: $error');
        setState(() {
          _hasRealtimeError = true;
        });
      },
    );

    // Listen to past appointments stream
    _pastSubscription = _appointmentService.pastAppointmentsStream.listen(
      (appointments) {
        debugPrint('AppointmentListScreen: Received ${appointments.length} past appointments from stream');
        _processPastAppointments(appointments);
      },
      onError: (error) {
        debugPrint('AppointmentListScreen: Error in past appointments stream: $error');
        setState(() {
          _hasRealtimeError = true;
        });
      },
    );
  }

  /// Process upcoming appointments from real-time stream
  void _processUpcomingAppointments(List<Map<String, dynamic>> appointments) {
    if (!mounted) return;

    // Filter expired appointments from upcoming and add them to past
    final List<Map<String, dynamic>> filteredUpcoming = [];
    final List<Map<String, dynamic>> expiredAppointments = [];

    for (final appointment in appointments) {
      if (_isAppointmentExpired(appointment)) {
        // Add expired status to the appointment for display
        final expiredAppointment = Map<String, dynamic>.from(appointment);
        expiredAppointment['effective_status'] = 'Expired';
        expiredAppointments.add(expiredAppointment);
      } else {
        filteredUpcoming.add(appointment);
      }
    }

    setState(() {
      _upcomingAppointments = filteredUpcoming;
      _isLoading = false;
      _error = null;
    });

    // If we have expired appointments, add them to past appointments
    if (expiredAppointments.isNotEmpty) {
      _addExpiredToPastAppointments(expiredAppointments);
    }
  }

  /// Process past appointments from real-time stream
  void _processPastAppointments(List<Map<String, dynamic>> appointments) {
    if (!mounted) return;

    // Add effective status for expired appointments in past list
    final processedPast = appointments.map((appointment) {
      final processed = Map<String, dynamic>.from(appointment);
      if (appointment['status'] == 'Expired' ||
          (appointment['status'] == 'Pending' && _isAppointmentExpired(appointment))) {
        processed['effective_status'] = 'Expired';
      }
      return processed;
    }).toList();

    // Sort by date (most recent first)
    processedPast.sort((a, b) {
      final dateA = DateTime.parse(a['appointment_date']);
      final dateB = DateTime.parse(b['appointment_date']);
      return dateB.compareTo(dateA);
    });

    setState(() {
      _pastAppointments = processedPast;
      _isLoading = false;
      _error = null;
    });
  }

  /// Add expired appointments to past appointments list
  void _addExpiredToPastAppointments(List<Map<String, dynamic>> expiredAppointments) {
    final allPastAppointments = [..._pastAppointments, ...expiredAppointments];

    // Sort by date (most recent first)
    allPastAppointments.sort((a, b) {
      final dateA = DateTime.parse(a['appointment_date']);
      final dateB = DateTime.parse(b['appointment_date']);
      return dateB.compareTo(dateA);
    });

    setState(() {
      _pastAppointments = allPastAppointments;
    });
  }

  Future<void> _loadAppointments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final upcoming = await _appointmentService.getUpcomingAppointments();
      final past = await _appointmentService.getPastAppointments();

      // Filter expired appointments from upcoming and add them to past
      final List<Map<String, dynamic>> filteredUpcoming = [];
      final List<Map<String, dynamic>> expiredAppointments = [];

      for (final appointment in upcoming) {
        if (_isAppointmentExpired(appointment)) {
          // Add expired status to the appointment for display
          final expiredAppointment = Map<String, dynamic>.from(appointment);
          expiredAppointment['effective_status'] = 'Expired';
          expiredAppointments.add(expiredAppointment);
        } else {
          filteredUpcoming.add(appointment);
        }
      }

      // Add effective status for expired appointments in past list
      final processedPast = past.map((appointment) {
        final processed = Map<String, dynamic>.from(appointment);
        if (appointment['status'] == 'Expired' ||
            (appointment['status'] == 'Pending' && _isAppointmentExpired(appointment))) {
          processed['effective_status'] = 'Expired';
        }
        return processed;
      }).toList();

      // Combine past appointments with newly expired ones
      final allPastAppointments = [...processedPast, ...expiredAppointments];

      // Sort by date (most recent first)
      allPastAppointments.sort((a, b) {
        final dateA = DateTime.parse(a['appointment_date']);
        final dateB = DateTime.parse(b['appointment_date']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _upcomingAppointments = filteredUpcoming;
        _pastAppointments = allPastAppointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load appointments. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    try {
      debugPrint('AppointmentListScreen: Manual refresh triggered');

      // Show brief loading indicator
      if (mounted) {
        EnhancedToasts.showInfo(
          context,
          'Refreshing appointments...',
          duration: const Duration(seconds: 1),
        );
      }

      // Trigger manual refresh of appointment data
      await _appointmentService.refreshAppointmentData();

      debugPrint('AppointmentListScreen: Manual refresh completed');
    } catch (e) {
      debugPrint('AppointmentListScreen: Error during manual refresh: $e');
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'Failed to refresh appointments',
        );
      }
    }
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _upcomingSubscription?.cancel();
    _pastSubscription?.cancel();

    // Dispose tab controller
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
              Colors.grey[50]!,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: primaryBlue),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'My Appointments',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              // Real-time connection status indicator
                              if (_isRealtimeConnected || _hasRealtimeError) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isRealtimeConnected
                                          ? Icons.wifi
                                          : Icons.wifi_off,
                                      size: 12,
                                      color: _isRealtimeConnected
                                          ? primaryGreen
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isRealtimeConnected
                                          ? 'Live updates'
                                          : 'Manual refresh',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _isRealtimeConnected
                                            ? primaryGreen
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: primaryBlue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AppointmentScreen(),
                              ),
                            ).then((_) {
                              // Trigger refresh when returning from appointment booking
                              if (_isRealtimeConnected) {
                                // Real-time will handle the update automatically
                                debugPrint('AppointmentListScreen: Returned from booking, real-time will update');
                              } else {
                                // Manual refresh if real-time is not connected
                                debugPrint('AppointmentListScreen: Returned from booking, triggering manual refresh');
                                _handleRefresh();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tab bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: primaryBlue,
                        indicator: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Upcoming'),
                          Tab(text: 'Past'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tab bar view
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: primaryBlue,
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[400],
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadAppointments,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              RefreshIndicator(
                                onRefresh: _handleRefresh,
                                color: primaryBlue,
                                child: _buildAppointmentsList(_upcomingAppointments, true),
                              ),
                              RefreshIndicator(
                                onRefresh: _handleRefresh,
                                color: primaryBlue,
                                child: _buildAppointmentsList(_pastAppointments, false),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments, bool isUpcoming) {
    if (appointments.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUpcoming ? Icons.event_available : Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isUpcoming ? 'No upcoming appointments' : 'No past appointments',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUpcoming
                      ? 'Book an appointment to get started'
                      : 'Your appointment history will appear here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_isRealtimeConnected) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sync,
                          size: 16,
                          color: primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Real-time updates active',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onCancel: isUpcoming ? () => _cancelAppointment(appointment['id']) : null,
          isCancelling: _cancellingAppointmentId == appointment['id'],
        );
      },
    );
  }

  void _cancelAppointment(String id) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during operation
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Cancel Appointment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this appointment? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performCancelAppointment(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancelAppointment(String id) async {
    // Store the current context before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Set loading state
      setState(() {
        _cancellingAppointmentId = id;
      });

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Cancelling appointment...'),
            ],
          ),
          duration: const Duration(seconds: 30), // Long duration for loading
          backgroundColor: primaryBlue,
        ),
      );

      // Cancel the appointment
      await _appointmentService.cancelAppointment(id);

      // Reload appointments to reflect changes
      await _loadAppointments();

      // Clear loading state
      setState(() {
        _cancellingAppointmentId = null;
      });

      // Hide loading snackbar and show success message
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 16),
              const Text('Appointment cancelled successfully'),
            ],
          ),
          backgroundColor: primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Clear loading state
      setState(() {
        _cancellingAppointmentId = null;
      });

      // Hide loading snackbar and show error message
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Failed to cancel appointment. Please try again.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _performCancelAppointment(id),
          ),
        ),
      );
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onCancel;
  final bool isCancelling;

  const _AppointmentCard({
    required this.appointment,
    this.onCancel,
    this.isCancelling = false,
  });

  String _formatTimeRange(String startTime, String endTime) {
    try {
      // Parse time strings (format: "HH:mm:ss")
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');

      if (startParts.length >= 2 && endParts.length >= 2) {
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);

        // Format to user-friendly format
        final startFormatted = _formatTime(startHour, startMinute);
        final endFormatted = _formatTime(endHour, endMinute);

        return '$startFormatted - $endFormatted';
      }
    } catch (e) {
      // Fallback to original time if parsing fails
    }
    return startTime;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    // Get effective status (considering expired appointments)
    final effectiveStatus = appointment['effective_status'] ?? appointment['status'];

    final bool isUpcoming = effectiveStatus == 'Pending';
    final bool isCancelled = effectiveStatus == 'Cancelled';
    final bool isCompleted = effectiveStatus == 'Completed';
    final bool isExpired = effectiveStatus == 'Expired';

    // Format date - handle both DateTime and String formats
    DateTime appointmentDate;
    if (appointment['appointment_date'] is String) {
      appointmentDate = DateTime.parse(appointment['appointment_date']);
    } else {
      appointmentDate = appointment['appointment_date'] ?? DateTime.now();
    }
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(appointmentDate);

    // Format time range using day slot information
    String timeStr = appointment['appointment_time']?.toString() ?? '';

    if (appointment['day_slots'] != null) {
      final daySlot = appointment['day_slots'];
      final startTime = daySlot['time_slot']?.toString() ?? '';
      final endTime = daySlot['end_time']?.toString() ?? '';

      if (startTime.isNotEmpty && endTime.isNotEmpty) {
        // Format times to user-friendly format
        timeStr = _formatTimeRange(startTime, endTime);
      }
    }

    // Get pet name
    final petName = appointment['pets']?['name'] ?? appointment['pet_id'] ?? 'Unknown Pet';

    // Determine status color
    Color statusColor;
    if (isUpcoming) {
      statusColor = primaryGreen;
    } else if (isCancelled) {
      statusColor = Colors.red;
    } else if (isCompleted) {
      statusColor = Colors.blue;
    } else if (isExpired) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isUpcoming
                    ? Icons.event_available
                    : (isCancelled
                        ? Icons.cancel
                        : (isExpired
                            ? Icons.schedule_outlined
                            : Icons.check_circle)),
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  effectiveStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Appointment details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service name (placeholder since we don't have service field yet)
                const Text(
                  'Pet Appointment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Date and time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.pets, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Pet: $petName',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                // Action buttons for upcoming appointments
                if (isUpcoming && onCancel != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel button with loading state
                      isCancelling
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cancelling...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextButton.icon(
                              onPressed: onCancel,
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Cancel'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}