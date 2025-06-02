import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/models/notification.dart';
import 'package:pet_smart/services/notification_preferences_service.dart';
import 'package:pet_smart/services/push_notification_service.dart';
import 'dart:convert';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationPreferencesService _preferencesService = NotificationPreferencesService();
  final PushNotificationService _pushService = PushNotificationService();

  /// Create a new notification
  Future<bool> createNotification({
    required String title,
    required String message,
    required String type,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final targetUserId = userId ?? user?.id;

      if (targetUserId == null) {
        debugPrint('NotificationService: No user ID provided');
        return false;
      }

      // Check if notifications are enabled for this type
      final isEnabled = await _preferencesService.isNotificationEnabled(type, 'in_app');
      if (!isEnabled) {
        debugPrint('NotificationService: Notifications disabled for type: $type');
        return false;
      }

      final notificationData = {
        'user_id': targetUserId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert notification and get the created notification with ID
      final response = await _supabase
          .from('notifications')
          .insert(notificationData)
          .select('id')
          .single();

      final notificationId = response['id'] as String;
      debugPrint('NotificationService: Notification created successfully with ID: $notificationId');

      // Show local notification if user preferences allow it
      await _showLocalNotification(
        title: title,
        message: message,
        type: type,
        data: data,
        notificationId: notificationId,
      );

      return true;
    } catch (e) {
      debugPrint('NotificationService: Error creating notification: $e');
      return false;
    }
  }

  /// Get user notifications
  Future<List<AppNotification>> getUserNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      PostgrestFilterBuilder query = _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', user.id);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('NotificationService: Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      debugPrint('NotificationService: Notification marked as read');
      return true;
    } catch (e) {
      debugPrint('NotificationService: Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('is_read', false);

      debugPrint('NotificationService: All notifications marked as read');
      return true;
    } catch (e) {
      debugPrint('NotificationService: Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return 0;
      }

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      final List<dynamic> data = response as List<dynamic>;
      return data.length;
    } catch (e) {
      debugPrint('NotificationService: Error getting unread count: $e');
      return 0;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      debugPrint('NotificationService: Notification deleted');
      return true;
    } catch (e) {
      debugPrint('NotificationService: Error deleting notification: $e');
      return false;
    }
  }

  /// Clear all notifications
  Future<bool> clearAllNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', user.id);

      debugPrint('NotificationService: All notifications cleared');
      return true;
    } catch (e) {
      debugPrint('NotificationService: Error clearing notifications: $e');
      return false;
    }
  }

  // Specific notification creators for different app events

  /// Create appointment notification
  Future<bool> createAppointmentNotification({
    required String title,
    required String message,
    required String appointmentId,
    String? userId,
  }) async {
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.appointment,
      userId: userId,
      data: {'appointment_id': appointmentId},
    );
  }

  /// Create order notification
  Future<bool> createOrderNotification({
    required String title,
    required String message,
    required String orderId,
    String? userId,
  }) async {
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.order,
      userId: userId,
      data: {'order_id': orderId},
    );
  }

  /// Create pet notification
  Future<bool> createPetNotification({
    required String title,
    required String message,
    required String petId,
    String? userId,
  }) async {
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.pet,
      userId: userId,
      data: {'pet_id': petId},
    );
  }

  /// Create promotional notification
  Future<bool> createPromotionalNotification({
    required String title,
    required String message,
    String? productId,
    String? userId,
  }) async {
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.promotional,
      userId: userId,
      data: productId != null ? {'product_id': productId} : null,
    );
  }

  /// Create system notification
  Future<bool> createSystemNotification({
    required String title,
    required String message,
    String? userId,
  }) async {
    return await createNotification(
      title: title,
      message: message,
      type: NotificationType.system,
      userId: userId,
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    String? notificationId,
  }) async {
    try {
      // Check if push notifications are enabled for this type
      final isPushEnabled = await _preferencesService.isNotificationEnabled(type, 'push');
      if (!isPushEnabled) {
        debugPrint('NotificationService: Local notifications disabled for type: $type');
        return;
      }

      // Create structured payload for deep linking
      final payload = json.encode({
        'type': type,
        'data': data ?? {},
        'title': title,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'notification_id': notificationId, // Include notification ID for marking as read
      });

      // Show local notification
      await _pushService.showLocalNotification(
        title: title,
        body: message,
        payload: payload,
      );

      debugPrint('NotificationService: Push notification sent successfully');
    } catch (e) {
      debugPrint('NotificationService: Error sending local notification: $e');
    }
  }
}
