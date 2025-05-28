import 'package:flutter/material.dart';
import 'package:pet_smart/components/status_banner.dart';
import 'package:pet_smart/services/day_slots_service.dart';
import 'package:pet_smart/services/appointment_service.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

class AppointmentTimePage extends StatefulWidget {
  final DateTime selectedDate;
  final String? selectedPetId;
  final String? selectedService;

  const AppointmentTimePage({
    super.key,
    required this.selectedDate,
    this.selectedPetId,
    this.selectedService,
  });

  @override
  State<AppointmentTimePage> createState() => _AppointmentTimePageState();
}

class _AppointmentTimePageState extends State<AppointmentTimePage> {
  List<DaySlotAvailability> _availableSlots = [];
  int? _selectedIndex;
  bool _isLoading = true;
  String? _error;
  final DaySlotsService _daySlotsService = DaySlotsService();
  final AppointmentService _appointmentService = AppointmentService();

  /// Check if a time slot has passed for the current day
  bool _isTimeSlotUnavailable(DaySlotAvailability slotAvailability) {
    final now = DateTime.now();
    final selectedDate = widget.selectedDate;

    // Only check for unavailability if the selected date is today
    if (selectedDate.year != now.year ||
        selectedDate.month != now.month ||
        selectedDate.day != now.day) {
      return false;
    }

    // Get the start time of the slot
    final slotStartTime = slotAvailability.daySlot.startTime;

    // Create DateTime for the slot time today
    final slotDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      slotStartTime.hour,
      slotStartTime.minute,
    );

    // Check if the slot time has passed
    return now.isAfter(slotDateTime);
  }

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final slots = await _daySlotsService.getAvailableSlots(widget.selectedDate);

      setState(() {
        _availableSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load available time slots. Please try again.';
        _isLoading = false;
      });
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
                                          onPressed: _loadAvailableSlots,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryBlue,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  )
                                : _availableSlots.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              color: Colors.grey,
                                              size: 48,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'No time slots available for this date',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _availableSlots.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 18),
                                        itemBuilder: (context, index) {
                                          final slotAvailability = _availableSlots[index];
                                          final isSelected = _selectedIndex == index;
                                          final isUnavailable = _isTimeSlotUnavailable(slotAvailability);
                                          final isAvailable = slotAvailability.isAvailable && !isUnavailable;
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
                                          slotAvailability.daySlot.formattedTimeRange,
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
                                          isUnavailable ? 'Unavailable' : slotAvailability.availabilityText,
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
                          _selectedIndex! < _availableSlots.length &&
                          _availableSlots[_selectedIndex!].isAvailable)
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
                            onPressed: () async {
                              final selectedSlot = _availableSlots[_selectedIndex!];
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);

                              // Check if the selected time slot is unavailable
                              if (_isTimeSlotUnavailable(selectedSlot)) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('This time slot is no longer available for today. Please select a future time.'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }

                              try {
                                // Create appointment using the new service
                                await _appointmentService.createAppointment(
                                  petId: widget.selectedPetId ?? '',
                                  appointmentDate: widget.selectedDate,
                                  appointmentTime: selectedSlot.daySlot.startTime.toString().substring(11, 19), // Extract time part
                                  daySlotId: selectedSlot.daySlot.id,
                                  status: 'Pending',
                                );

                                // Navigate to confirmation page
                                if (mounted) {
                                  navigator.pushReplacement(
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
                                }
                              } catch (e) {
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to create appointment: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
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


