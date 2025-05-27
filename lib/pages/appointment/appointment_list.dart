import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_smart/pages/appointment/appointment.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background
const Color primaryGreen = Color(0xFF4CAF50);  // Success green

// A service class to manage appointments
class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();

  factory AppointmentService() {
    return _instance;
  }

  AppointmentService._internal();

  // List to store all appointments
  final List<Map<String, dynamic>> _appointments = [
    // Sample appointments for demo
    {
      'id': '1',
      'service': 'Full Grooming – Small Breed',
      'date': DateTime.now().add(const Duration(days: 2)),
      'time': '10:30 am - 12:00 pm',
      'status': 'Upcoming',
      'petName': 'Max',
      // Removed price field
    },
    {
      'id': '2',
      'service': 'Teeth Brushing',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'time': '2:00 pm - 4:00 pm',
      'status': 'Completed',
      'petName': 'Buddy',
      // Removed price field
    },
    {
      'id': '3',
      'service': 'Bath & Blowdry – Small Breed',
      'date': DateTime.now().add(const Duration(days: 7)),
      'time': '7:30 am - 9:30 am',
      'status': 'Upcoming',
      'petName': 'Daisy',
      // Removed price field
    },
  ];

  // Get all appointments
  List<Map<String, dynamic>> get appointments => _appointments;

  // Add a new appointment
  void addAppointment(Map<String, dynamic> appointment) {
    _appointments.add(appointment);
  }

  // Cancel an appointment
  void cancelAppointment(String id) {
    final index = _appointments.indexWhere((appointment) => appointment['id'] == id);
    if (index != -1) {
      _appointments[index]['status'] = 'Cancelled';
    }
  }

  // Get upcoming appointments
  List<Map<String, dynamic>> getUpcomingAppointments() {
    return _appointments.where((appointment) =>
      appointment['status'] == 'Upcoming').toList();
  }

  // Get past appointments
  List<Map<String, dynamic>> getPastAppointments() {
    return _appointments.where((appointment) =>
      appointment['status'] == 'Completed' || appointment['status'] == 'Cancelled').toList();
  }
}

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
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
                        const Expanded(
                          child: Text(
                            'My Appointments',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
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
                              setState(() {});
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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentsList(_appointmentService.getUpcomingAppointments(), true),
                    _buildAppointmentsList(_appointmentService.getPastAppointments(), false),
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
      return Center(
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
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onCancel: isUpcoming ? () => _cancelAppointment(appointment['id']) : null,
          // Removed onReschedule parameter
        );
      },
    );
  }

  void _cancelAppointment(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _appointmentService.cancelAppointment(id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment cancelled')),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onCancel;

  const _AppointmentCard({
    required this.appointment,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUpcoming = appointment['status'] == 'Upcoming';
    final bool isCancelled = appointment['status'] == 'Cancelled';

    // Format date
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(appointment['date']);

    // Determine status color
    Color statusColor;
    if (isUpcoming) {
      statusColor = primaryGreen;
    } else if (isCancelled) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
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
                  isUpcoming ? Icons.event_available : (isCancelled ? Icons.cancel : Icons.check_circle),
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  appointment['status'],
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
                // Service name
                Text(
                  appointment['service'],
                  style: const TextStyle(
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
                      appointment['time'],
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
                      'Pet: ${appointment['petName']}',
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
                      // Only Cancel button is kept
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
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