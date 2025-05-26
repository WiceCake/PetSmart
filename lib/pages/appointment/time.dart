import 'package:flutter/material.dart';
import 'package:pet_smart/components/nav_bar.dart';
import 'package:pet_smart/components/status_banner.dart';
import 'package:pet_smart/pages/appointment/appointment_list.dart'; // Import appointment list to access the service

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
    const primaryColor = Color(0xFF233A63);
    const accentColor = Color(0xFFE57373);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Time Slot',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Available Time Slots",
                  style: TextStyle(
                    fontSize: 20,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
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
                                  ? accentColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: isSelected ? Colors.white : primaryColor,
                                  size: 28,
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Text(
                                    slot.time,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : primaryColor,
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
                                          ? accentColor
                                          : isAvailable
                                              ? accentColor
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
                        backgroundColor: accentColor,
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
                          'service': 'Full Grooming – Small Breed', // This would normally come from the selected service
                          'date': DateTime.now().add(const Duration(days: 3)), // This would come from the calendar page
                          'time': _timeSlots[_selectedIndex!].time,
                          'status': 'Upcoming',
                          'petName': 'Fluffy', // This would come from pet selection
                          'price': '₱600', // This would come from selected service
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
                        style: TextStyle(fontSize: 18, letterSpacing: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_showBanner)
            Align(
              alignment: Alignment.topCenter,
              child: CustomConfirmationPage(),
            ),
        ],
      ),
    );
  }
}

class _TimeSlot {
  final String time;
  final int slotsLeft;
  _TimeSlot(this.time, this.slotsLeft);
}
