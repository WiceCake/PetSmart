import 'package:flutter/material.dart';
import 'package:pet_smart/services/email_verification_service.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationWidget extends StatefulWidget {
  const EmailVerificationWidget({super.key});

  @override
  State<EmailVerificationWidget> createState() => _EmailVerificationWidgetState();
}

class _EmailVerificationWidgetState extends State<EmailVerificationWidget> {
  final EmailVerificationService _verificationService = EmailVerificationService();
  bool _isLoading = false;
  bool _isVerified = false;
  bool _canResend = true;
  int _resendCooldown = 0;

  static const Color _primaryColor = Color(0xFF233A63);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _warningColor = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Check if email is confirmed in Supabase auth
      final isEmailConfirmed = user.emailConfirmedAt != null;

      // Also check our custom email_verified field in profiles
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('email_verified')
          .eq('id', user.id)
          .maybeSingle();

      final emailVerified = profileResponse?['email_verified'] as bool? ?? false;

      setState(() {
        _isVerified = isEmailConfirmed && emailVerified;
      });
    } catch (e) {
      debugPrint('Error checking verification status: $e');
    }
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

  Future<void> _sendVerificationEmail() async {
    if (!_canResend || _isLoading) return;

    setState(() {
      _isLoading = true;
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsVerified() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _verificationService.markAsVerified();

      if (!mounted) return;

      if (result.isSuccess) {
        EnhancedToasts.showSuccess(
          context,
          'Email verified successfully!',
          duration: const Duration(seconds: 2),
        );

        // Refresh verification status
        await _checkVerificationStatus();
      } else {
        EnhancedToasts.showError(
          context,
          result.errorMessage ?? 'Failed to verify email.',
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isVerified ? _successColor.withValues(alpha: 0.3) : _warningColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isVerified ? Icons.verified_outlined : Icons.email_outlined,
                color: _isVerified ? _successColor : _warningColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isVerified
                          ? 'Your email address is verified'
                          : 'Verify your email for enhanced security',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _successColor,
                    ),
                  ),
                ),
            ],
          ),
          if (!_isVerified) ...[
            const SizedBox(height: 16),
            Text(
              'Benefits of email verification:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildBenefitItem('🔒 Enhanced account security'),
            _buildBenefitItem('📧 Order confirmations and updates'),
            _buildBenefitItem('🔄 Easy password recovery'),
            _buildBenefitItem('🎁 Exclusive offers and promotions'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canResend && !_isLoading ? _sendVerificationEmail : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canResend ? _primaryColor : Colors.grey[300],
                  foregroundColor: _canResend ? Colors.white : Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: _canResend ? 2 : 0,
                ),
                child: _isLoading
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
                            ? 'Send Verification Email'
                            : 'Resend in ${_resendCooldown}s',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Fallback verification button for testing
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: !_isLoading ? _markAsVerified : null,
                style: TextButton.styleFrom(
                  foregroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Mark as Verified (Testing)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
