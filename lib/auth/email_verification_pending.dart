import 'package:flutter/material.dart';
import 'package:pet_smart/services/email_verification_service.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';
import 'package:pet_smart/components/enhanced_dialogs.dart';

class EmailVerificationPendingScreen extends StatefulWidget {
  final String? userEmail;

  const EmailVerificationPendingScreen({
    super.key,
    this.userEmail,
  });

  @override
  State<EmailVerificationPendingScreen> createState() => _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState extends State<EmailVerificationPendingScreen> {
  final EmailVerificationService _verificationService = EmailVerificationService();
  bool _isResending = false;
  bool _canResend = true;
  int _resendCooldown = 0;

  static const Color _primaryColor = Color(0xFF233A63);
  static const Color _accentColor = Color(0xFFE57373);

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    if (_resendCooldown > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _resendCooldown--;
            _canResend = _resendCooldown == 0;
          });
          if (_resendCooldown > 0) {
            _startCooldownTimer();
          }
        }
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final result = await _verificationService.sendVerificationEmail();

      if (!mounted) return;

      if (result.isSuccess) {
        EnhancedToasts.showSuccess(
          context,
          'Verification email sent! Please check your inbox and spam folder.',
          duration: const Duration(seconds: 3),
        );

        // Start cooldown
        setState(() {
          _resendCooldown = 60; // 60 seconds cooldown
          _canResend = false;
        });
        _startCooldownTimer();
      } else {
        EnhancedToasts.showError(
          context,
          result.errorMessage ?? 'Failed to send verification email.',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'An unexpected error occurred. Please try again.',
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await EnhancedDialogs.showLogoutConfirmation(context);

    if (confirmed == true) {
      await _verificationService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
  }

  String get _displayEmail {
    final email = widget.userEmail ?? _verificationService.getCurrentUserEmail();
    return email ?? 'your email address';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Email verification icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 60,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Check Your Email',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'We\'ve sent a verification link to',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Email address
                    Text(
                      _displayEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Instructions
                    Text(
                      'Please click the verification link in your email to continue. Don\'t forget to check your spam folder!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Resend button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canResend && !_isResending ? _resendVerificationEmail : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canResend ? _primaryColor : Colors.grey[300],
                          foregroundColor: _canResend ? Colors.white : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: _canResend ? 2 : 0,
                        ),
                        child: _isResending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _canResend
                                    ? 'Resend Verification Email'
                                    : 'Resend in ${_resendCooldown}s',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Help text
                    Text(
                      'Still having trouble? Contact our support team for assistance.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
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
}
