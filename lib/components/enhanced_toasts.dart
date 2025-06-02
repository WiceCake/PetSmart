import 'package:flutter/material.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background
const Color successGreen = Color(0xFF4CAF50);  // Success green
const Color warningOrange = Color(0xFFFF9800); // Warning orange

/// Enhanced toast notification service with Material Design styling
class EnhancedToasts {

  /// Show a success toast with green styling and check icon
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showEnhancedSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show an error toast with red styling and error icon
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showEnhancedSnackBar(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: accentRed,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show a warning toast with orange styling and warning icon
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showEnhancedSnackBar(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: warningOrange,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show an info toast with blue styling and info icon
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showEnhancedSnackBar(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: primaryBlue,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show a logout success toast with custom styling
  static void showLogoutSuccess(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "You've been logged out successfully. See you soon!",
      icon: Icons.logout_rounded,
      backgroundColor: primaryBlue,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show a registration cancellation success toast
  static void showRegistrationCancelled(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Registration cancelled. Your account has been removed.",
      icon: Icons.cancel_rounded,
      backgroundColor: warningOrange,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Pet Management Toasts

  /// Show pet addition success toast
  static void showPetAdded(BuildContext context, String petName) {
    _showEnhancedSnackBar(
      context,
      message: "Welcome $petName to your PetSmart family! 🐾",
      icon: Icons.pets_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show pet update success toast
  static void showPetUpdated(BuildContext context, String petName) {
    _showEnhancedSnackBar(
      context,
      message: "$petName's information has been updated successfully!",
      icon: Icons.edit_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show pet deletion confirmation toast
  static void showPetDeleted(BuildContext context, String petName) {
    _showEnhancedSnackBar(
      context,
      message: "$petName has been removed from your account.",
      icon: Icons.delete_rounded,
      backgroundColor: warningOrange,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Appointment Toasts

  /// Show appointment booking success toast
  static void showAppointmentBooked(BuildContext context, String petName, String date) {
    _showEnhancedSnackBar(
      context,
      message: "Great! $petName's appointment is confirmed for $date. We can't wait to see you both!",
      icon: Icons.event_available_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show appointment cancellation toast
  static void showAppointmentCancelled(BuildContext context, String petName) {
    _showEnhancedSnackBar(
      context,
      message: "$petName's appointment has been cancelled. You can reschedule anytime!",
      icon: Icons.event_busy_rounded,
      backgroundColor: warningOrange,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Shopping & Cart Toasts

  /// Show add to cart success toast
  static void showAddedToCart(BuildContext context, String productName, int quantity) {
    final quantityText = quantity == 1 ? "item" : "items";
    _showEnhancedSnackBar(
      context,
      message: "Perfect! Added $quantity $quantityText of $productName to your cart.",
      icon: Icons.shopping_cart_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
      actionLabel: "View Cart",
    );
  }

  /// Show cart item removed toast
  static void showRemovedFromCart(BuildContext context, String productName) {
    _showEnhancedSnackBar(
      context,
      message: "$productName has been removed from your cart.",
      icon: Icons.remove_shopping_cart_rounded,
      backgroundColor: warningOrange,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show cart cleared toast
  static void showCartCleared(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Your cart has been cleared. Ready for a fresh start!",
      icon: Icons.clear_all_rounded,
      backgroundColor: primaryBlue,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show purchase success toast
  static void showPurchaseSuccess(BuildContext context, String orderId) {
    _showEnhancedSnackBar(
      context,
      message: "Order placed successfully! Your order #$orderId is being prepared with care.",
      icon: Icons.check_circle_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // Profile & Account Toasts

  /// Show profile update success toast
  static void showProfileUpdated(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Your profile has been updated successfully! Looking great!",
      icon: Icons.person_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show address added success toast
  static void showAddressAdded(BuildContext context, String label) {
    _showEnhancedSnackBar(
      context,
      message: "Perfect! Your $label address has been saved successfully.",
      icon: Icons.location_on_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show address updated success toast
  static void showAddressUpdated(BuildContext context, String label) {
    _showEnhancedSnackBar(
      context,
      message: "Your $label address has been updated successfully!",
      icon: Icons.edit_location_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show address deleted toast
  static void showAddressDeleted(BuildContext context, String label) {
    _showEnhancedSnackBar(
      context,
      message: "Your $label address has been removed from your account.",
      icon: Icons.delete_rounded,
      backgroundColor: warningOrange,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show default address set toast
  static void showDefaultAddressSet(BuildContext context, String label) {
    _showEnhancedSnackBar(
      context,
      message: "Great! Your $label address is now set as default.",
      icon: Icons.home_rounded,
      backgroundColor: primaryBlue,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Order Status Toasts

  /// Show order status update toast
  static void showOrderStatusUpdate(BuildContext context, String orderId, String status) {
    String message;
    IconData icon;
    Color backgroundColor;

    switch (status.toLowerCase()) {
      case 'order preparation':
        message = "Good news! Your order #$orderId is being prepared with care.";
        icon = Icons.kitchen_rounded;
        backgroundColor = primaryBlue;
        break;
      case 'pending delivery':
        message = "Your order #$orderId is ready and will be delivered soon!";
        icon = Icons.local_shipping_rounded;
        backgroundColor = warningOrange;
        break;
      case 'order confirmation':
        message = "Almost there! Your order #$orderId is out for delivery.";
        icon = Icons.delivery_dining_rounded;
        backgroundColor = primaryBlue;
        break;
      case 'completed':
        message = "Fantastic! Your order #$orderId has been delivered successfully.";
        icon = Icons.check_circle_rounded;
        backgroundColor = successGreen;
        break;
      default:
        message = "Your order #$orderId status has been updated to $status.";
        icon = Icons.info_rounded;
        backgroundColor = primaryBlue;
    }

    _showEnhancedSnackBar(
      context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // Chat & Messaging Toasts

  /// Show message sent success toast
  static void showMessageSent(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Message sent successfully! 💬",
      icon: Icons.send_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }



  /// Show chat connection error toast
  static void showChatConnectionError(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Connection lost. Trying to reconnect...",
      icon: Icons.wifi_off_rounded,
      backgroundColor: warningOrange,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show chat reconnected toast
  static void showChatReconnected(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Connected! You can continue chatting.",
      icon: Icons.wifi_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show new message notification toast
  static void showNewMessage(BuildContext context, String senderName) {
    _showEnhancedSnackBar(
      context,
      message: "New message from $senderName",
      icon: Icons.message_rounded,
      backgroundColor: primaryBlue,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
      actionLabel: "View",
    );
  }

  /// Show conversation reopened toast
  static void showConversationReopened(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Conversation reopened! Support will respond soon.",
      icon: Icons.refresh_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show conversation resolved toast
  static void showConversationResolved(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Conversation has been resolved by support.",
      icon: Icons.check_circle_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // General Action Toasts

  /// Show item liked toast
  static void showItemLiked(BuildContext context, String itemName) {
    _showEnhancedSnackBar(
      context,
      message: "Added $itemName to your favorites! ❤️",
      icon: Icons.favorite_rounded,
      backgroundColor: accentRed,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show item unliked toast
  static void showItemUnliked(BuildContext context, String itemName) {
    _showEnhancedSnackBar(
      context,
      message: "Removed $itemName from your favorites.",
      icon: Icons.favorite_border_rounded,
      backgroundColor: primaryBlue,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show data sync success toast
  static void showDataSynced(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "All your data is up to date! Everything's synced perfectly.",
      icon: Icons.sync_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // Privacy & Security Toasts

  /// Show privacy settings updated toast
  static void showPrivacySettingsUpdated(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Your privacy preferences have been updated successfully.",
      icon: Icons.privacy_tip_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show security settings updated toast
  static void showSecuritySettingsUpdated(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Your security settings have been updated successfully.",
      icon: Icons.security_rounded,
      backgroundColor: successGreen,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show password reset email sent toast
  static void showPasswordResetSent(BuildContext context, String email) {
    _showEnhancedSnackBar(
      context,
      message: "Password reset email sent to $email. Please check your inbox and spam folder.",
      icon: Icons.email_rounded,
      backgroundColor: primaryBlue,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show account deletion initiated toast
  static void showAccountDeletionInitiated(BuildContext context) {
    _showEnhancedSnackBar(
      context,
      message: "Account deletion process has been initiated. You will receive a confirmation email shortly.",
      icon: Icons.info_rounded,
      backgroundColor: warningOrange,
      textColor: Colors.white,
      iconColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Private method to show enhanced snackbar with sophisticated styling
  static void _showEnhancedSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              // Enhanced icon container with sophisticated styling
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: backgroundColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Enhanced text with better typography
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    height: 1.3,
                  ),
                ),
              ),
              // Action button with enhanced styling if provided
              if (actionLabel != null && onActionPressed != null) ...[
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: TextButton(
                    onPressed: onActionPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 12,
        duration: duration,
        // Remove default action since we're handling it in the content
        action: null,
      ),
    );
  }
}
