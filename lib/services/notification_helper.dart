import 'package:pet_smart/services/notification_service.dart';

/// Helper service to create notifications for specific app events
class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();

  // Appointment-related notifications

  /// Notify when appointment is confirmed
  static Future<void> notifyAppointmentConfirmed({
    required String appointmentId,
    required String petName,
    required String appointmentDate,
    required String appointmentTime,
    String? userId,
  }) async {
    await _notificationService.createAppointmentNotification(
      title: 'Appointment Confirmed',
      message: 'Your appointment for $petName has been confirmed for $appointmentDate at $appointmentTime.',
      appointmentId: appointmentId,
      userId: userId,
    );
  }

  /// Notify appointment reminder (24 hours before)
  static Future<void> notifyAppointmentReminder24h({
    required String appointmentId,
    required String petName,
    required String appointmentDate,
    required String appointmentTime,
    String? userId,
  }) async {
    await _notificationService.createAppointmentNotification(
      title: 'Appointment Reminder',
      message: 'Don\'t forget! $petName has an appointment tomorrow at $appointmentTime.',
      appointmentId: appointmentId,
      userId: userId,
    );
  }

  /// Notify appointment reminder (1 hour before)
  static Future<void> notifyAppointmentReminder1h({
    required String appointmentId,
    required String petName,
    required String appointmentTime,
    String? userId,
  }) async {
    await _notificationService.createAppointmentNotification(
      title: 'Appointment Starting Soon',
      message: '$petName\'s appointment is starting in 1 hour at $appointmentTime.',
      appointmentId: appointmentId,
      userId: userId,
    );
  }

  /// Notify when appointment is cancelled
  static Future<void> notifyAppointmentCancelled({
    required String appointmentId,
    required String petName,
    required String appointmentDate,
    String? userId,
  }) async {
    await _notificationService.createAppointmentNotification(
      title: 'Appointment Cancelled',
      message: 'Your appointment for $petName on $appointmentDate has been cancelled.',
      appointmentId: appointmentId,
      userId: userId,
    );
  }

  /// Notify when appointment is completed
  static Future<void> notifyAppointmentCompleted({
    required String appointmentId,
    required String petName,
    String? userId,
  }) async {
    await _notificationService.createAppointmentNotification(
      title: 'Appointment Completed',
      message: '$petName\'s appointment has been completed successfully.',
      appointmentId: appointmentId,
      userId: userId,
    );
  }

  // Order-related notifications

  /// Notify when order is confirmed
  static Future<void> notifyOrderConfirmed({
    required String orderId,
    required double totalAmount,
    String? userId,
  }) async {
    await _notificationService.createOrderNotification(
      title: 'Order Confirmed',
      message: 'Your order #$orderId for ₱${totalAmount.toStringAsFixed(2)} has been confirmed.',
      orderId: orderId,
      userId: userId,
    );
  }

  /// Notify when order status changes
  static Future<void> notifyOrderStatusChanged({
    required String orderId,
    required String newStatus,
    String? userId,
  }) async {
    String message;
    switch (newStatus.toLowerCase()) {
      case 'preparing':
      case 'order preparation':
        message = 'Your order #$orderId is being prepared.';
        break;
      case 'pending delivery':
        message = 'Your order #$orderId is ready for delivery.';
        break;
      case 'order confirmation':
        message = 'Your order #$orderId has been delivered. Please confirm receipt.';
        break;
      case 'completed':
        message = 'Your order #$orderId has been completed. Thank you for shopping with us!';
        break;
      default:
        message = 'Your order #$orderId status has been updated to $newStatus.';
    }

    await _notificationService.createOrderNotification(
      title: 'Order Update',
      message: message,
      orderId: orderId,
      userId: userId,
    );
  }

  // Pet-related notifications

  /// Notify when new pet is added
  static Future<void> notifyPetAdded({
    required String petId,
    required String petName,
    String? userId,
  }) async {
    await _notificationService.createPetNotification(
      title: 'Pet Added',
      message: 'Welcome $petName to your PetSmart family!',
      petId: petId,
      userId: userId,
    );
  }

  /// Notify vaccination reminder
  static Future<void> notifyVaccinationReminder({
    required String petId,
    required String petName,
    required String vaccinationType,
    String? userId,
  }) async {
    await _notificationService.createPetNotification(
      title: 'Vaccination Reminder',
      message: '$petName is due for $vaccinationType vaccination. Please schedule an appointment.',
      petId: petId,
      userId: userId,
    );
  }

  /// Notify pet birthday
  static Future<void> notifyPetBirthday({
    required String petId,
    required String petName,
    required int age,
    String? userId,
  }) async {
    await _notificationService.createPetNotification(
      title: 'Happy Birthday! 🎉',
      message: 'Today is $petName\'s birthday! Your furry friend is now $age years old.',
      petId: petId,
      userId: userId,
    );
  }

  // Promotional notifications

  /// Notify about new product arrivals
  static Future<void> notifyNewArrivals({
    required String productName,
    String? productId,
    String? userId,
  }) async {
    await _notificationService.createPromotionalNotification(
      title: 'New Arrival',
      message: 'Check out our new product: $productName!',
      productId: productId,
      userId: userId,
    );
  }

  /// Notify about sales and discounts
  static Future<void> notifySaleOffer({
    required String offerTitle,
    required String discountPercentage,
    String? productId,
    String? userId,
  }) async {
    await _notificationService.createPromotionalNotification(
      title: 'Special Offer! 🏷️',
      message: '$offerTitle - Get $discountPercentage% off!',
      productId: productId,
      userId: userId,
    );
  }

  /// Notify about general promotions
  static Future<void> notifyPromotion({
    required String title,
    required String message,
    String? productId,
    String? userId,
  }) async {
    await _notificationService.createPromotionalNotification(
      title: title,
      message: message,
      productId: productId,
      userId: userId,
    );
  }

  // System notifications

  /// Notify about app updates
  static Future<void> notifyAppUpdate({
    required String version,
    required String features,
    String? userId,
  }) async {
    await _notificationService.createSystemNotification(
      title: 'App Update Available',
      message: 'PetSmart v$version is now available with new features: $features',
      userId: userId,
    );
  }

  /// Notify about maintenance
  static Future<void> notifyMaintenance({
    required String maintenanceTime,
    required String duration,
    String? userId,
  }) async {
    await _notificationService.createSystemNotification(
      title: 'Scheduled Maintenance',
      message: 'PetSmart will be under maintenance on $maintenanceTime for approximately $duration.',
      userId: userId,
    );
  }

  /// Notify about security alerts
  static Future<void> notifySecurityAlert({
    required String alertMessage,
    String? userId,
  }) async {
    await _notificationService.createSystemNotification(
      title: 'Security Alert',
      message: alertMessage,
      userId: userId,
    );
  }

  // Utility methods

  /// Send welcome notification to new users
  static Future<void> sendWelcomeNotification(String? userId) async {
    await _notificationService.createSystemNotification(
      title: 'Welcome to PetSmart! 🐾',
      message: 'Thank you for joining PetSmart! Explore our features to take the best care of your pets.',
      userId: userId,
    );
  }

  /// Send notification when user completes profile setup
  static Future<void> notifyProfileCompleted(String? userId) async {
    await _notificationService.createSystemNotification(
      title: 'Profile Setup Complete',
      message: 'Your profile has been set up successfully! You can now access all PetSmart features.',
      userId: userId,
    );
  }
}
