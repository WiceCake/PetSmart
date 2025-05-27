import 'package:flutter/material.dart';
import 'package:pet_smart/components/nav_bar.dart';
import 'package:pet_smart/components/status_banner.dart';
import 'package:pet_smart/pages/appointment/appointment_list.dart'; // Import appointment list to access the service

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

class AppointmentTimePage extends StatefulWidget {
  const AppointmentTimePage({super.key});

  @override
  State<AppointmentTimePage> createState() => _AppointmentTimePageState();
}

class _AppointmentTimePageState extends State<AppointmentTimePage> {
  final List<_TimeSlot> _timeSlots = [
    _TimeSlot('7:30 am - 9:30 am', 3),
    _TimeSlot('10:30 am - 12:00 pm', 0),
    _TimeSlot('2:00 pm - 4:00 pm', 5),
  ];

  int? _selectedIndex;
  bool _showBanner = false;
  bool _success = true;
  String _bannerMessage = "";
  final AppointmentService _appointmentService = AppointmentService(); // Use the appointment service

  void _showStatusBanner({required bool success, required String message}) async {
    setState(() {
      _showBanner = true;
      _success = success;
      _bannerMessage = message;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _showBanner = false);
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => BottomNavigationApp()),
          (route) => false,
        );
      }
    }
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
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: primaryBlue),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Select Time Slot',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Available Time Slots",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Time slots
                      Expanded(
                        child: ListView.separated(
                          itemCount: _timeSlots.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            final slot = _timeSlots[index];
                            final isSelected = _selectedIndex == index;
                            final isAvailable = slot.slotsLeft > 0;
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isAvailable ? 1 : 0.5,
                              child: GestureDetector(
                                onTap: isAvailable
                                    ? () {
                                        setState(() {
                                          _selectedIndex = index;
                                        });
                                      }
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryRed
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryRed
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: primaryRed.withValues(alpha: 0.18),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: isSelected ? Colors.white : primaryBlue,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Text(
                                          slot.time,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isAvailable
                                              ? "${slot.slotsLeft} slot${slot.slotsLeft > 1 ? 's' : ''} left"
                                              : "Full",
                                          style: TextStyle(
                                            color: isSelected
                                                ? primaryRed
                                                : isAvailable
                                                    ? primaryRed
                                                    : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_selectedIndex != null &&
                          _timeSlots[_selectedIndex!].slotsLeft > 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () {
                              // Create a new appointment and add it to the service
                              final newAppointment = {
                                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                'service': 'Full Grooming – Small Breed',
                                'date': DateTime.now().add(const Duration(days: 3)),
                                'time': _timeSlots[_selectedIndex!].time,
                                'status': 'Upcoming',
                                'petName': 'Fluffy',
                                'price': '₱600',
                              };

                              // Add the appointment to the service
                              _appointmentService.addAppointment(newAppointment);

                              // Navigate to confirmation page
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const CustomConfirmationPage(
                                    title: "Successfully",
                                    message: "The shop has already received your schedule.",
                                    buttonText: "Back to home page",
                                    icon: Icons.check_circle,
                                    iconColor: Colors.green,
                                  ),
                                ),
                              );
                            },
                            label: const Text(
                              "Confirm Appointment",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSlot {
  final String time;
  final int slotsLeft;
  _TimeSlot(this.time, this.slotsLeft);
}
