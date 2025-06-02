import 'package:flutter/material.dart';
import 'package:pet_smart/auth/profile_setup.dart';
import 'package:pet_smart/services/profile_completion_service.dart';
import 'package:pet_smart/components/enhanced_dialogs.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class UserDetailsScreen extends StatefulWidget {
  final String? userId;
  final String? userEmail;

  const UserDetailsScreen({
    super.key,
    this.userId,
    this.userEmail,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  DateTime? selectedBirthdate;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      // If no user is found on init, show a helpful message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _error = 'Session not found. Please complete registration first.';
        });
      });
    }
  }





  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your birthdate',
      cancelText: 'Cancel',
      confirmText: 'Select',
      fieldLabelText: 'Enter date',
      fieldHintText: 'mm/dd/yyyy',
      errorFormatText: 'Enter valid date',
      errorInvalidText: 'Enter date in valid range',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF233A63), // Header background color
              onPrimary: Colors.white, // Header text color
              surface: Colors.white, // Calendar background
              onSurface: Color(0xFF233A63), // Calendar text color
              secondary: Color(0xFFE57373), // Selected date color
              onSecondary: Colors.white, // Selected date text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF233A63), // Button text color
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              elevation: 8,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedBirthdate) {
      setState(() {
        selectedBirthdate = picked;
      });
    }
  }

  bool _validateInputs() {
    if (firstNameController.text.trim().isEmpty) {
      setState(() {
        _error = 'First name is required.';
      });
      return false;
    }
    if (lastNameController.text.trim().isEmpty) {
      setState(() {
        _error = 'Last name is required.';
      });
      return false;
    }
    // Phone number is now optional - only validate format if provided
    if (phoneController.text.trim().isNotEmpty &&
        !RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phoneController.text.trim())) {
      setState(() {
        _error = 'Please enter a valid phone number.';
      });
      return false;
    }

    if (selectedBirthdate == null) {
      setState(() {
        _error = 'Please select your birthdate.';
      });
      return false;
    }
    return true;
  }

  Future<void> _submitDetails() async {
    setState(() {
      _error = null;
    });

    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;

    // Use passed userId if available, otherwise get from current user
    String? userId = widget.userId ?? supabase.auth.currentUser?.id;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'User information not found. Please register again.';
      });
      return;
    }

    // Proceed with saving details using the userId
    await _saveUserDetailsWithId(userId);
  }

  Future<void> _saveUserDetailsWithId(String userId) async {
    final supabase = Supabase.instance.client;

    try {
      // Prepare phone number data - use null if empty
      final phoneNumber = phoneController.text.trim().isEmpty ? null : phoneController.text.trim();

      await supabase.from('profiles').upsert({
        'id': userId,
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'phone_number': phoneNumber,
        'mobile_number': phoneNumber, // Use same phone for both fields
        'birthdate': selectedBirthdate!.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => ProfileSetupScreen(
            userId: userId,
            userEmail: widget.userEmail,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to save details. Please try again.';
      });
    }
  }

  /// Handle cancellation of registration process
  Future<void> _handleCancellation() async {
    if (!mounted) return;

    final confirmed = await EnhancedDialogs.showRegistrationCancellation(context);

    if (confirmed == true && mounted) {
      // Show loading dialog and get dismissal function
      final dismissDialog = await EnhancedDialogs.showLoadingDialog(context, message: 'Cancelling registration...');

      try {
        // Delete the incomplete registration
        final success = await ProfileCompletionService().deleteIncompleteRegistration();

        if (mounted) {
          // Dismiss loading dialog
          dismissDialog();

          if (success) {
            // Show success toast
            EnhancedToasts.showRegistrationCancelled(context);

            // Small delay to let the toast show before navigation
            await Future.delayed(const Duration(milliseconds: 500));

            if (mounted) {
              // Navigate back to auth wrapper - this will properly handle the auth state
              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
            }
          } else {
            // Show error toast
            EnhancedToasts.showError(
              context,
              'Failed to cancel registration. Please try again.',
            );
          }
        }
      } catch (e) {
        debugPrint('Error during registration cancellation: $e');
        if (mounted) {
          // Dismiss loading dialog
          dismissDialog();

          // Show error toast
          EnhancedToasts.showError(
            context,
            'An error occurred while cancelling registration. Please try again.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF233A63);
    const accentColor = Color(0xFFE57373);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Show cancellation dialog when back navigation is attempted
          await _handleCancellation();
        }
      },
      child: Scaffold(
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
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with Cancel Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Spacer for centering
                    const Text(
                      'User Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _handleCancellation,
                        tooltip: 'Cancel Registration',
                      ),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title Text
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tell us about yourself',
                              style: TextStyle(
                                fontSize: 24,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                  _AnimatedInputField(
                    controller: firstNameController,
                    hintText: 'First Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _AnimatedInputField(
                    controller: lastNameController,
                    hintText: 'Last Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _AnimatedInputField(
                    controller: phoneController,
                    hintText: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _BirthdateField(
                    selectedDate: selectedBirthdate,
                    onTap: _selectBirthdate,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_error!.contains('Session not found') || _error!.contains('Authentication')) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                              },
                              child: const Text(
                                'Go back to Registration',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _submitDetails,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'NEXT',
                              style: TextStyle(fontSize: 18, letterSpacing: 1),
                            ),
                    ),
                  ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;

  const _AnimatedInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color(0xFF233A63)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _BirthdateField extends StatefulWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const _BirthdateField({
    required this.selectedDate,
    required this.onTap,
  });

  @override
  State<_BirthdateField> createState() => _BirthdateFieldState();
}

class _BirthdateFieldState extends State<_BirthdateField> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.selectedDate != null
                      ? [
                          const Color(0xFF233A63).withValues(alpha: 0.1),
                          const Color(0xFFF2F2F2),
                        ]
                      : [
                          const Color(0xFFF2F2F2),
                          const Color(0xFFF8F8F8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.selectedDate != null
                      ? const Color(0xFF233A63).withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: _isPressed ? 12 : 8,
                    offset: Offset(0, _isPressed ? 4 : 2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.selectedDate != null
                            ? const Color(0xFF233A63).withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: widget.selectedDate != null
                            ? const Color(0xFF233A63)
                            : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Birthdate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.selectedDate != null
                                ? _formatDate(widget.selectedDate!)
                                : 'Select your birthdate',
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.selectedDate != null
                                  ? Colors.black87
                                  : Colors.grey[500],
                              fontWeight: widget.selectedDate != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isPressed ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF233A63).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF233A63),
                          size: 20,
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
    );
  }
}