import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet_smart/auth/user_details.dart';
import 'package:pet_smart/auth/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/config/app_config.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String userId;
  final bool isEmailVerification; // true for email verification from settings, false for signup

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.userId,
    this.isEmailVerification = false,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all fields are filled
    if (_getOTPCode().length == 6) {
      _verifyOTP();
    }
  }

  Future<void> _verifyOTP() async {
    final otpCode = _getOTPCode();
    if (otpCode.length != 6) {
      setState(() {
        _error = 'Please enter the complete 6-digit code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!AppConfig.isConfigured()) {
        setState(() {
          _isLoading = false;
          _error = 'App configuration error. Please contact support.';
        });
        return;
      }

      final supabase = Supabase.instance.client;

      // Verify the OTP - use appropriate type based on context
      final response = await supabase.auth.verifyOTP(
        email: widget.email,
        token: otpCode,
        type: widget.isEmailVerification ? OtpType.email : OtpType.signup,
      );

      debugPrint('OTP Verification response:');
      debugPrint('User: ${response.user?.id}');
      debugPrint('Session: ${response.session?.accessToken != null ? "Present" : "Null"}');
      debugPrint('Email confirmed: ${response.user?.emailConfirmedAt}');

      if (response.user != null && response.session != null) {
        // Check if email is now confirmed
        if (response.user!.emailConfirmedAt != null) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email verified successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Small delay to ensure session is properly set
          await Future.delayed(const Duration(milliseconds: 300));

          if (!mounted) return;

          if (widget.isEmailVerification) {
            // For email verification from settings, show success and go back
            await Future.delayed(const Duration(seconds: 1));
            if (!mounted) return;

            Navigator.of(context).pop(); // Go back to settings

            // Show additional success message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Email verification completed successfully!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            // For signup flow, navigate to user details screen
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (context, animation, secondaryAnimation) => UserDetailsScreen(
                  userId: widget.userId,
                  userEmail: widget.email,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
            _error = 'Email verification failed. Please try again.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Invalid verification code. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        String errorMessage = e.toString().toLowerCase();
        debugPrint('OTP Verification error: $e');

        if (errorMessage.contains('invalid') || errorMessage.contains('expired') || errorMessage.contains('token')) {
          _error = 'Invalid or expired verification code. Please try again or request a new code.';
        } else if (errorMessage.contains('network') || errorMessage.contains('connection') || errorMessage.contains('timeout')) {
          _error = 'Network error. Please check your connection and try again.';
        } else if (errorMessage.contains('rate') || errorMessage.contains('limit')) {
          _error = 'Too many attempts. Please wait a moment before trying again.';
        } else if (errorMessage.contains('email') && errorMessage.contains('not found')) {
          _error = 'Email not found. Please check your email address.';
        } else {
          _error = 'Verification failed. Please try again or contact support.';
        }
      });
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      if (!AppConfig.isConfigured()) {
        setState(() {
          _isResending = false;
          _error = 'App configuration error. Please contact support.';
        });
        return;
      }

      final supabase = Supabase.instance.client;

      // Resend OTP - use appropriate type based on context
      if (widget.isEmailVerification) {
        // For email verification from settings, use signInWithOtp
        await supabase.auth.signInWithOtp(
          email: widget.email,
          shouldCreateUser: false,
        );
      } else {
        // For signup flow, use resend
        await supabase.auth.resend(
          type: OtpType.signup,
          email: widget.email,
        );
      }

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      // Clear OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      // Start countdown again
      _startResendCountdown();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification code sent! Please check your email.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isResending = false;
        String errorMessage = e.toString().toLowerCase();
        debugPrint('Resend OTP error: $e');

        if (errorMessage.contains('rate') || errorMessage.contains('limit')) {
          _error = 'Too many resend attempts. Please wait before requesting another code.';
        } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
          _error = 'Network error. Please check your connection and try again.';
        } else {
          _error = 'Failed to resend code. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF233A63);
    const accentColor = Color(0xFFE57373);

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
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
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
                        icon: const Icon(Icons.arrow_back, color: primaryColor),
                        onPressed: () {
                          if (widget.isEmailVerification) {
                            // For email verification from settings, just go back
                            Navigator.of(context).pop();
                          } else {
                            // For signup flow, go back to auth screen
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                transitionDuration: const Duration(milliseconds: 400),
                                pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          }
                        },
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
                          // Logo Container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.mark_email_read_outlined,
                              size: 60,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Title
                          const Text(
                            'Verify Your Email',
                            style: TextStyle(
                              fontSize: 24,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          Text(
                            'We sent a 6-digit code to\n${widget.email}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // OTP Input Fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return _OTPInputField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                onChanged: (value) => _onOTPChanged(value, index),
                              );
                            }),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
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
                            ),
                          ],
                          const SizedBox(height: 32),
                          // Verify Button
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
                              onPressed: _isLoading ? null : _verifyOTP,
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
                                      'VERIFY',
                                      style: TextStyle(fontSize: 18, letterSpacing: 1),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Resend Code
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't receive the code?",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: _resendCountdown > 0 || _isResending ? null : _resendOTP,
                                child: _isResending
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          color: accentColor,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _resendCountdown > 0
                                            ? "Resend in ${_resendCountdown}s"
                                            : "Resend",
                                        style: TextStyle(
                                          color: _resendCountdown > 0 ? Colors.grey : accentColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ],
                          ),

                          // Development bypass button (remove in production)
                          if (!widget.isEmailVerification) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading ? null : _skipEmailVerification,
                              child: const Text(
                                'Skip Email Verification (Development)',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
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
    );
  }

  // Development bypass method (remove in production)
  Future<void> _skipEmailVerification() async {
    if (_isLoading) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Development Bypass'),
        content: const Text(
          'This will bypass email verification for development purposes only. '
          'In production, proper email verification should be implemented.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verification bypassed for development!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to user details screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => UserDetailsScreen(
            userId: widget.userId,
            userEmail: widget.email,
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
        _error = 'Failed to bypass verification. Please try the normal verification process.';
      });
    }
  }
}

class _OTPInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;

  const _OTPInputField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF233A63);

    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
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
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
