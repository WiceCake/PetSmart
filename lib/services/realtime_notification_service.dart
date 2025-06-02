import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/services/notification_preferences_service.dart';
import 'package:pet_smart/services/push_notification_service.dart';
import 'dart:async';

/// Service for handling real-time push notifications based on database changes
class RealtimeNotificationService {
  static final RealtimeNotificationService _instance = RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationPreferencesService _preferencesService = NotificationPreferencesService();
  final PushNotificationService _pushService = PushNotificationService();

  // Subscriptions for cleanup
  RealtimeChannel? _ordersSubscription;
  RealtimeChannel? _appointmentsSubscription;
  RealtimeChannel? _messagesSubscription;

  // Current user tracking
  String? _currentUserId;
  bool _isInitialized = false;

  /// Initialize real-time notification subscriptions
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('RealtimeNotificationService: Already initialized');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('RealtimeNotificationService: User not authenticated, skipping initialization');
      return;
    }

    _currentUserId = user.id;
    debugPrint('RealtimeNotificationService: Initializing for user: ${user.id}');

    try {
      await _setupRealtimeSubscriptions();
      _isInitialized = true;
      debugPrint('RealtimeNotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('RealtimeNotificationService: Error during initialization: $e');
    }
  }

  /// Setup real-time subscriptions for orders, appointments, and messages
  Future<void> _setupRealtimeSubscriptions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Unsubscribe from previous subscriptions
    await _ordersSubscription?.unsubscribe();
    await _appointmentsSubscription?.unsubscribe();
    await _messagesSubscription?.unsubscribe();

    // Subscribe to orders changes for current user
    _ordersSubscription = _supabase
        .channel('realtime_notifications_orders:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleOrderStatusChange(payload),
        )
        .subscribe();

    // Subscribe to appointments changes for current user
    _appointmentsSubscription = _supabase
        .channel('realtime_notifications_appointments:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleAppointmentStatusChange(payload),
        )
        .subscribe();

    // Subscribe to messages for conversations where user is involved
    _messagesSubscription = _supabase
        .channel('realtime_notifications_messages:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) => _handleNewMessage(payload),
        )
        .subscribe();

    debugPrint('RealtimeNotificationService: Subscribed to orders, appointments, and messages for user $userId');
  }

  /// Handle order status changes
  Future<void> _handleOrderStatusChange(PostgresChangePayload payload) async {
    debugPrint('RealtimeNotificationService: Order status change detected');
    debugPrint('RealtimeNotificationService: Payload - oldRecord: ${payload.oldRecord}, newRecord: ${payload.newRecord}');

    try {
      final oldRecord = payload.oldRecord;
      final newRecord = payload.newRecord;

      final oldStatus = oldRecord['status'] as String?;
      final newStatus = newRecord['status'] as String?;
      final orderId = newRecord['id'] as String?;
      final totalAmount = newRecord['total_amount'] as num?;

      // Only send notification if status actually changed
      if (oldStatus == newStatus || orderId == null) return;

      // Check if user has order notifications enabled
      final isEnabled = await _preferencesService.isNotificationEnabled('order', 'push');
      if (!isEnabled) {
        debugPrint('RealtimeNotificationService: Order notifications disabled for user');
        return;
      }

      await _sendOrderStatusNotification(
        orderId: orderId,
        newStatus: newStatus ?? 'Unknown',
        totalAmount: totalAmount?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('RealtimeNotificationService: Error handling order status change: $e');
    }
  }

  /// Handle appointment status changes
  Future<void> _handleAppointmentStatusChange(PostgresChangePayload payload) async {
    debugPrint('RealtimeNotificationService: Appointment status change detected');
    debugPrint('RealtimeNotificationService: Payload - oldRecord: ${payload.oldRecord}, newRecord: ${payload.newRecord}');

    try {
      final oldRecord = payload.oldRecord;
      final newRecord = payload.newRecord;

      final oldStatus = oldRecord['status'] as String?;
      final newStatus = newRecord['status'] as String?;
      final appointmentId = newRecord['id'] as String?;
      final appointmentDate = newRecord['appointment_date'] as String?;
      final appointmentTime = newRecord['appointment_time'] as String?;

      // Only send notification if status actually changed
      if (oldStatus == newStatus || appointmentId == null) return;

      // Check if user has appointment notifications enabled
      final isEnabled = await _preferencesService.isNotificationEnabled('appointment', 'push');
      if (!isEnabled) {
        debugPrint('RealtimeNotificationService: Appointment notifications disabled for user');
        return;
      }

      await _sendAppointmentStatusNotification(
        appointmentId: appointmentId,
        newStatus: newStatus ?? 'Unknown',
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
      );
    } catch (e) {
      debugPrint('RealtimeNotificationService: Error handling appointment status change: $e');
    }
  }

  /// Handle new messages (only admin messages to user)
  Future<void> _handleNewMessage(PostgresChangePayload payload) async {
    debugPrint('RealtimeNotificationService: New message detected');
    debugPrint('RealtimeNotificationService: Payload - newRecord: ${payload.newRecord}');

    try {
      final newRecord = payload.newRecord;

      final senderId = newRecord['sender_id'] as String?;
      final senderType = newRecord['sender_type'] as String?;
      final message = newRecord['message'] as String?;
      final conversationId = newRecord['conversation_id'] as String?;

      // Only send notification for admin messages (not user's own messages)
      if (senderType != 'admin' || senderId == _currentUserId) return;

      // Check if user has message notifications enabled
      final isEnabled = await _preferencesService.isNotificationEnabled('messages', 'push');
      if (!isEnabled) {
        debugPrint('RealtimeNotificationService: Message notifications disabled for user');
        return;
      }

      await _sendNewMessageNotification(
        message: message ?? 'New message',
        conversationId: conversationId,
      );
    } catch (e) {
      debugPrint('RealtimeNotificationService: Error handling new message: $e');
    }
  }

  /// Send order status notification
  Future<void> _sendOrderStatusNotification({
    required String orderId,
    required String newStatus,
    required double totalAmount,
  }) async {
    String title;
    String body;
    String payload = 'order:$orderId';

    switch (newStatus.toLowerCase()) {
      case 'preparing':
      case 'order preparation':
        title = '🍽️ Order Being Prepared';
        body = 'Your order is now being prepared! We\'ll notify you when it\'s ready for delivery.';
        break;
      case 'pending delivery':
        title = '🚚 Order Out for Delivery';
        body = 'Your order is on its way! Track your delivery in the app.';
        break;
      case 'order confirmation':
        title = '📦 Order Delivered';
        body = 'Your order has been delivered! Please confirm receipt in the app.';
        break;
      case 'completed':
        title = '✅ Order Completed';
        body = 'Thank you! Your order has been completed successfully.';
        break;
      case 'cancelled':
        title = '❌ Order Cancelled';
        body = 'Your order has been cancelled. If you have questions, please contact support.';
        break;
      default:
        title = '📋 Order Update';
        body = 'Your order status has been updated to: $newStatus';
    }

    await _pushService.showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );

    debugPrint('RealtimeNotificationService: Sent order notification - $title');
  }

  /// Send appointment status notification
  Future<void> _sendAppointmentStatusNotification({
    required String appointmentId,
    required String newStatus,
    String? appointmentDate,
    String? appointmentTime,
  }) async {
    String title;
    String body;
    String payload = 'appointment:$appointmentId';

    final dateTimeStr = appointmentDate != null && appointmentTime != null
        ? 'on $appointmentDate at $appointmentTime'
        : '';

    switch (newStatus.toLowerCase()) {
      case 'confirmed':
        title = '✅ Appointment Confirmed';
        body = 'Your appointment has been confirmed $dateTimeStr';
        break;
      case 'completed':
        title = '🎉 Appointment Completed';
        body = 'Your appointment has been completed. Thank you for visiting PetSmart!';
        break;
      case 'cancelled':
        title = '❌ Appointment Cancelled';
        body = 'Your appointment $dateTimeStr has been cancelled.';
        break;
      default:
        title = '📅 Appointment Update';
        body = 'Your appointment status has been updated to: $newStatus';
    }

    await _pushService.showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );

    debugPrint('RealtimeNotificationService: Sent appointment notification - $title');
  }

  /// Send new message notification
  Future<void> _sendNewMessageNotification({
    required String message,
    String? conversationId,
  }) async {
    final title = '💬 New Message';
    final body = message.length > 50 ? '${message.substring(0, 50)}...' : message;

    await _pushService.showChatNotification(
      title: title,
      body: body,
      conversationId: conversationId,
    );

    debugPrint('RealtimeNotificationService: Sent message notification - $title');
  }

  /// Dispose of resources and clean up subscriptions
  Future<void> dispose() async {
    debugPrint('RealtimeNotificationService: Disposing resources...');
    
    // Unsubscribe from real-time subscriptions
    await _ordersSubscription?.unsubscribe();
    await _appointmentsSubscription?.unsubscribe();
    await _messagesSubscription?.unsubscribe();
    
    // Clear current user tracking
    _currentUserId = null;
    _isInitialized = false;
    
    debugPrint('RealtimeNotificationService: Disposed successfully');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
