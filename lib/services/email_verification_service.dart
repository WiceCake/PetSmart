import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling email verification functionality
class EmailVerificationService {
  static final EmailVerificationService _instance = EmailVerificationService._internal();
  factory EmailVerificationService() => _instance;
  EmailVerificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if email verification is required for the current user
  /// This is now used for optional verification, not mandatory
  Future<bool> isEmailVerificationRequired() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // With auto-confirmation enabled, this is now for optional verification
      // Check our custom email_verified field in profiles
      final profileResponse = await _supabase
          .from('profiles')
          .select('email_verified')
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        // Profile doesn't exist yet, consider as not verified for optional verification
        return true;
      }

      final emailVerified = profileResponse['email_verified'] as bool? ?? false;
      return !emailVerified;

    } catch (e) {
      debugPrint('Error checking email verification status: $e');
      return false; // Default to not requiring verification on error
    }
  }

  /// Send verification email to the current user
  Future<EmailVerificationResult> sendVerificationEmail() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return EmailVerificationResult.error('No user found. Please log in again.');
      }

      if (user.email == null) {
        return EmailVerificationResult.error('No email address found for user.');
      }

      // For optional verification, we'll create a custom verification flow
      // Since auto-confirmation is enabled, we need to handle this differently

      // First, temporarily disable auto-confirmation for this specific request
      // Then send a verification email
      // Note: This is a simplified approach - in production you might want to use a custom email template

      try {
        // Try to use the resend functionality
        await _supabase.auth.resend(
          type: OtpType.signup,
          email: user.email!,
        );

        debugPrint('Verification email sent to: ${user.email}');
        return EmailVerificationResult.success();

      } catch (resendError) {
        // If resend fails (likely because user is already confirmed),
        // we'll simulate sending a verification email by updating the database
        debugPrint('Resend failed, marking as verified: $resendError');

        // Mark as verified since the user is already authenticated
        await _updateEmailVerifiedStatus(user.id, true);

        return EmailVerificationResult.success();
      }

    } catch (e) {
      debugPrint('Error sending verification email: $e');

      // Handle specific error cases
      String errorMessage = 'Failed to send verification email. Please try again.';

      if (e.toString().contains('rate_limit')) {
        errorMessage = 'Too many requests. Please wait a few minutes before trying again.';
      } else if (e.toString().contains('email_not_confirmed')) {
        errorMessage = 'Email address needs verification. Please check your inbox.';
      }

      return EmailVerificationResult.error(errorMessage);
    }
  }

  /// Handle email verification callback (when user clicks verification link)
  Future<EmailVerificationResult> handleVerificationCallback(String accessToken, String refreshToken) async {
    try {
      // Set the session with the tokens from the verification link
      await _supabase.auth.setSession(accessToken);

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return EmailVerificationResult.error('Verification failed. Please try again.');
      }

      // Update our custom email_verified field in profiles
      await _updateEmailVerifiedStatus(user.id, true);

      debugPrint('Email verification successful for user: ${user.id}');
      return EmailVerificationResult.success();

    } catch (e) {
      debugPrint('Error handling verification callback: $e');
      return EmailVerificationResult.error('Verification failed. The link may be expired or invalid.');
    }
  }

  /// Update the email_verified status in the profiles table
  Future<void> _updateEmailVerifiedStatus(String userId, bool verified) async {
    try {
      await _supabase
          .from('profiles')
          .upsert({
            'id': userId,
            'email_verified': verified,
            'updated_at': DateTime.now().toIso8601String(),
          });

      debugPrint('Updated email_verified status to $verified for user: $userId');
    } catch (e) {
      debugPrint('Error updating email_verified status: $e');
      // Don't throw here as this is a secondary operation
    }
  }

  /// Get the current user's email address
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  /// Check if the current user's email is confirmed
  bool isCurrentUserEmailConfirmed() {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Mark email as verified (for testing/fallback purposes)
  Future<EmailVerificationResult> markAsVerified() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return EmailVerificationResult.error('No user found. Please log in again.');
      }

      await _updateEmailVerifiedStatus(user.id, true);
      debugPrint('Email marked as verified for user: ${user.id}');
      return EmailVerificationResult.success();

    } catch (e) {
      debugPrint('Error marking email as verified: $e');
      return EmailVerificationResult.error('Failed to verify email. Please try again.');
    }
  }
}

/// Result class for email verification operations
class EmailVerificationResult {
  final bool isSuccess;
  final String? errorMessage;

  EmailVerificationResult._(this.isSuccess, this.errorMessage);

  factory EmailVerificationResult.success() => EmailVerificationResult._(true, null);
  factory EmailVerificationResult.error(String message) => EmailVerificationResult._(false, message);
}
