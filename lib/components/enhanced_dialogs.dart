import 'package:flutter/material.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background
const Color successGreen = Color(0xFF4CAF50);  // Success green
const Color warningOrange = Color(0xFFFF9800); // Warning orange

/// Enhanced dialog service with Material Design styling and animations
class EnhancedDialogs {

  /// Show a logout confirmation dialog
  static Future<bool?> showLogoutConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.logout_rounded,
          iconColor: accentRed,
          title: 'Logout',
          content: 'Are you sure you want to logout? You\'ll need to sign in again to access your account.',
          primaryButtonText: 'Logout',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Cancel',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  /// Show an enhanced registration cancellation dialog
  static Future<bool?> showRegistrationCancellation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.warning_rounded,
          iconColor: warningOrange,
          title: 'Cancel Registration',
          content: 'Are you sure you want to cancel registration? This will permanently delete your account and you\'ll need to start over.',
          primaryButtonText: 'Delete Account',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Keep Registration',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  // Pet Management Dialogs

  /// Show pet deletion confirmation dialog
  static Future<bool?> showPetDeletionConfirmation(BuildContext context, String petName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.pets_rounded,
          iconColor: accentRed,
          title: 'Remove $petName',
          content: 'Are you sure you want to remove $petName from your account? This action cannot be undone, but you can always add them back later.',
          primaryButtonText: 'Remove Pet',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Keep Pet',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  // Appointment Dialogs

  /// Show appointment cancellation confirmation dialog
  static Future<bool?> showAppointmentCancellation(BuildContext context, String petName, String date) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.event_busy_rounded,
          iconColor: warningOrange,
          title: 'Cancel Appointment',
          content: 'Are you sure you want to cancel $petName\'s appointment on $date? You can always reschedule for another time that works better for you.',
          primaryButtonText: 'Cancel Appointment',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Keep Appointment',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  // Shopping & Cart Dialogs

  /// Show cart clear confirmation dialog
  static Future<bool?> showCartClearConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.shopping_cart_rounded,
          iconColor: warningOrange,
          title: 'Clear Cart',
          content: 'Are you sure you want to remove all items from your cart? Don\'t worry, you can always add them back if you change your mind!',
          primaryButtonText: 'Clear Cart',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Keep Items',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  /// Show remove cart item confirmation dialog
  static Future<bool?> showRemoveCartItemConfirmation(BuildContext context, String productName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.remove_shopping_cart_rounded,
          iconColor: warningOrange,
          title: 'Remove Item',
          content: 'Remove $productName from your cart? You can always add it back later if you need it.',
          primaryButtonText: 'Remove Item',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Keep Item',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  // Address Management Dialogs

  /// Show address deletion confirmation dialog
  static Future<bool?> showAddressDeletionConfirmation(BuildContext context, String addressLabel) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.location_off_rounded,
          iconColor: accentRed,
          title: 'Delete Address',
          content: 'Are you sure you want to delete your $addressLabel address? You can always add it back later if needed.',
          primaryButtonText: 'Delete Address',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Keep Address',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  /// Show set default address confirmation dialog
  static Future<bool?> showSetDefaultAddressConfirmation(BuildContext context, String addressLabel) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.home_rounded,
          iconColor: primaryBlue,
          title: 'Set Default Address',
          content: 'Set your $addressLabel address as the default? This will be used for all future orders and deliveries.',
          primaryButtonText: 'Set as Default',
          primaryButtonColor: primaryBlue,
          secondaryButtonText: 'Cancel',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  // Order & Purchase Dialogs

  /// Show order cancellation confirmation dialog
  static Future<bool?> showOrderCancellationConfirmation(BuildContext context, String orderId) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.cancel_rounded,
          iconColor: accentRed,
          title: 'Cancel Order',
          content: 'Are you sure you want to cancel order #$orderId? If your order is already being prepared, cancellation may not be possible.',
          primaryButtonText: 'Cancel Order',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Keep Order',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  // General Action Dialogs

  /// Show unsaved changes confirmation dialog
  static Future<bool?> showUnsavedChangesConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.warning_rounded,
          iconColor: warningOrange,
          title: 'Unsaved Changes',
          content: 'You have unsaved changes that will be lost. Are you sure you want to leave without saving?',
          primaryButtonText: 'Leave Without Saving',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Continue Editing',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  /// Show data refresh confirmation dialog
  static Future<bool?> showDataRefreshConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.refresh_rounded,
          iconColor: primaryBlue,
          title: 'Refresh Data',
          content: 'This will reload all your data from the server. Any unsaved changes will be lost. Continue?',
          primaryButtonText: 'Refresh Now',
          primaryButtonColor: primaryBlue,
          secondaryButtonText: 'Cancel',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  /// Show a loading dialog with custom message
  /// Returns a function that can be called to dismiss the dialog
  static Future<VoidCallback> showLoadingDialog(
    BuildContext context, {
    String message = 'Please wait...',
  }) async {
    // Store the navigator before showing the dialog
    final navigator = Navigator.of(context);

    // Show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _LoadingDialog(message: message);
      },
    );

    // Return a dismissal function
    return () {
      try {
        navigator.pop();
      } catch (e) {
        debugPrint('Error dismissing loading dialog: $e');
      }
    };
  }

  /// Show account deletion confirmation dialog
  static Future<bool?> showAccountDeletionConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.delete_forever_rounded,
          iconColor: accentRed,
          title: 'Delete Account',
          content: 'Are you absolutely sure you want to delete your account? This action cannot be undone and will permanently remove all your data, including pets, appointments, and order history.',
          primaryButtonText: 'Delete Account',
          primaryButtonColor: accentRed,
          secondaryButtonText: 'Cancel',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  /// Show password change confirmation dialog
  static Future<bool?> showPasswordChangeConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EnhancedDialog(
          icon: Icons.lock_reset_rounded,
          iconColor: warningOrange,
          title: 'Change Password',
          content: 'You will receive a password reset email. After changing your password, you\'ll need to sign in again with your new credentials.',
          primaryButtonText: 'Send Reset Email',
          primaryButtonColor: primaryBlue,
          secondaryButtonText: 'Cancel',
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  /// Show data sharing explanation dialog
  static Future<void> showDataSharingInfo(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Data Sharing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: const Text(
            'When enabled, we may use your anonymized data to improve our services and provide personalized recommendations. This includes:\n\n• Pet care suggestions based on your pet\'s profile\n• Product recommendations\n• Service improvements\n\nYour personal information is never shared with third parties.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dismiss any currently shown dialog
  static void dismissDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Enhanced dialog widget with consistent Material Design styling
class _EnhancedDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final String primaryButtonText;
  final String secondaryButtonText;
  final Color primaryButtonColor;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  const _EnhancedDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.primaryButtonColor,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 12,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          minWidth: 280,
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with background circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 36,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.5,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Buttons
            Column(
              children: [
                // Secondary Button (Keep Registration) - Full width
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onSecondaryPressed,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryBlue, width: 1.5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      secondaryButtonText,
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Primary Button (Delete Account) - Full width
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPrimaryPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryButtonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 3,
                      shadowColor: primaryButtonColor.withValues(alpha: 0.3),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      primaryButtonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading dialog widget with spinner and message
class _LoadingDialog extends StatelessWidget {
  final String message;

  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}