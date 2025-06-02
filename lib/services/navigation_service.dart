import 'package:flutter/material.dart';
import 'package:pet_smart/pages/notifications_list.dart';
import 'package:pet_smart/pages/account/purchase_history.dart';
import 'package:pet_smart/pages/appointment/appointment_list.dart';
import 'package:pet_smart/pages/account/all_pets.dart';
import 'package:pet_smart/pages/shop/dashboard.dart';
import 'package:pet_smart/pages/messages/direct_chat_admin.dart';
import 'package:pet_smart/pages/messages/chat_history.dart';
import 'package:pet_smart/models/notification.dart';
import 'package:pet_smart/services/notification_service.dart';
import 'dart:convert';

/// Service to handle deep linking and navigation throughout the app
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final NotificationService _notificationService = NotificationService();

  // Pending navigation for when user needs to authenticate first
  String? _pendingRoute;

  // Callback for when notifications are marked as read
  VoidCallback? _onNotificationRead;

  /// Get the current navigation context
  BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate to notifications page
  Future<void> navigateToNotifications() async {
    final context = currentContext;
    if (context == null) {
      debugPrint('NavigationService: No context available for navigation');
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const NotificationsListPage(),
        ),
      );
      debugPrint('NavigationService: Successfully navigated to notifications');
    } catch (e) {
      debugPrint('NavigationService: Error navigating to notifications: $e');
    }
  }

  /// Navigate to chat page
  Future<void> navigateToChat({String? conversationId}) async {
    final context = currentContext;
    if (context == null) {
      debugPrint('NavigationService: No context available for navigation');
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DirectChatAdminPage(
            conversationId: conversationId,
          ),
        ),
      );
      debugPrint('NavigationService: Successfully navigated to chat');
    } catch (e) {
      debugPrint('NavigationService: Error navigating to chat: $e');
    }
  }

  /// Navigate to chat history
  Future<void> navigateToChatHistory() async {
    final context = currentContext;
    if (context == null) {
      debugPrint('NavigationService: No context available for navigation');
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ChatHistoryPage(),
        ),
      );
      debugPrint('NavigationService: Successfully navigated to chat history');
    } catch (e) {
      debugPrint('NavigationService: Error navigating to chat history: $e');
    }
  }

  /// Handle notification tap based on notification type and data
  Future<void> handleNotificationTap(String? payload) async {
    if (payload == null || payload.isEmpty) {
      debugPrint('NavigationService: No payload provided, navigating to notifications');
      await navigateToNotifications();
      return;
    }

    try {
      // Check for simple string payloads first (like chat notifications and real-time notifications)
      if (payload.startsWith('chat:')) {
        final conversationId = payload.substring('chat:'.length);
        if (conversationId.isNotEmpty) {
          await navigateToChat(conversationId: conversationId);
        } else {
          await navigateToChat();
        }
        return;
      } else if (payload == 'chat') {
        await navigateToChat();
        return;
      } else if (payload.startsWith('order:')) {
        // Handle real-time order notifications
        await _handleOrderNotification({'order_id': payload.substring('order:'.length)});
        return;
      } else if (payload.startsWith('appointment:')) {
        // Handle real-time appointment notifications
        await _handleAppointmentNotification({'appointment_id': payload.substring('appointment:'.length)});
        return;
      }

      // Parse the payload as JSON for complex notifications
      Map<String, dynamic> data;
      try {
        data = json.decode(payload) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('NavigationService: Failed to parse payload as JSON: $payload');
        // If payload is not JSON, treat it as simple string and navigate to notifications
        await navigateToNotifications();
        return;
      }

      final String? type = data['type'] as String?;
      final String? notificationId = data['notification_id'] as String?;
      debugPrint('NavigationService: Handling notification tap for type: $type, ID: $notificationId');

      // Mark notification as read if we have the ID
      if (notificationId != null) {
        await _markNotificationAsRead(notificationId);
      }

      // Route based on notification type
      switch (type) {
        case NotificationType.appointment:
          await _handleAppointmentNotification(data);
          break;
        case NotificationType.order:
          await _handleOrderNotification(data);
          break;
        case NotificationType.pet:
          await _handlePetNotification(data);
          break;
        case NotificationType.promotional:
          await _handlePromotionalNotification(data);
          break;
        case NotificationType.system:
        default:
          // For system notifications or unknown types, go to notifications page
          await navigateToNotifications();
          break;
      }
    } catch (e) {
      debugPrint('NavigationService: Error handling notification tap: $e');
      // Fallback to notifications page
      await navigateToNotifications();
    }
  }

  /// Mark notification as read
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      final success = await _notificationService.markAsRead(notificationId);
      if (success) {
        debugPrint('NavigationService: Notification $notificationId marked as read');
        // Trigger callback to refresh notification count
        _onNotificationRead?.call();
      } else {
        debugPrint('NavigationService: Failed to mark notification $notificationId as read');
      }
    } catch (e) {
      debugPrint('NavigationService: Error marking notification as read: $e');
    }
  }

  /// Set callback for when notifications are marked as read
  void setNotificationReadCallback(VoidCallback? callback) {
    _onNotificationRead = callback;
  }

  /// Handle appointment notification tap
  Future<void> _handleAppointmentNotification(Map<String, dynamic> data) async {
    final context = currentContext;
    if (context == null) return;

    try {
      // Navigate to appointment list page
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AppointmentListScreen(),
        ),
      );
      debugPrint('NavigationService: Navigated to appointment list');
    } catch (e) {
      debugPrint('NavigationService: Error navigating to appointments: $e');
      await navigateToNotifications();
    }
  }

  /// Handle order notification tap
  Future<void> _handleOrderNotification(Map<String, dynamic> data) async {
    final context = currentContext;
    if (context == null) return;

    try {
      // Navigate to purchase history page
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PurchaseHistoryPage(),
        ),
      );
      debugPrint('NavigationService: Navigated to purchase history');
    } catch (e) {
      debugPrint('NavigationService: Error navigating to purchase history: $e');
      await navigateToNotifications();
    }
  }

  /// Handle pet notification tap
  Future<void> _handlePetNotification(Map<String, dynamic> data) async {
    final context = currentContext;
    if (context == null) return;

    try {
      // Navigate to pets page with empty list (it will load its own data)
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AllPetsPage(pets: []),
        ),
      );
      debugPrint('NavigationService: Navigated to pets page');
    } catch (e) {
      debugPrint('NavigationService: Error navigating to pets: $e');
      await navigateToNotifications();
    }
  }

  /// Handle promotional notification tap
  Future<void> _handlePromotionalNotification(Map<String, dynamic> data) async {
    final context = currentContext;
    if (context == null) return;

    try {
      // Navigate to shop dashboard
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DashboardShopScreen(),
        ),
      );
      debugPrint('NavigationService: Navigated to shop dashboard');
    } catch (e) {
      debugPrint('NavigationService: Error navigating to shop: $e');
      await navigateToNotifications();
    }
  }

  /// Set pending navigation for after authentication
  void setPendingNavigation(String route, [Map<String, dynamic>? data]) {
    _pendingRoute = route;
    debugPrint('NavigationService: Set pending navigation to: $route');
  }

  /// Execute pending navigation after authentication
  Future<void> executePendingNavigation() async {
    if (_pendingRoute == null) return;

    debugPrint('NavigationService: Executing pending navigation to: $_pendingRoute');

    final route = _pendingRoute!;
    // final data = _pendingData; // Reserved for future use

    // Clear pending navigation
    _pendingRoute = null;

    // Execute the navigation
    if (route == 'notifications') {
      await navigateToNotifications();
    } else if (route == 'chat') {
      await navigateToChat();
    } else if (route.startsWith('chat:')) {
      final conversationId = route.substring('chat:'.length);
      await navigateToChat(conversationId: conversationId);
    } else if (route.startsWith('order:')) {
      await _handleOrderNotification({'order_id': route.substring('order:'.length)});
    } else if (route.startsWith('appointment:')) {
      await _handleAppointmentNotification({'appointment_id': route.substring('appointment:'.length)});
    } else {
      // Handle other pending routes if needed
      await navigateToNotifications();
    }
  }

  /// Check if there's pending navigation
  bool get hasPendingNavigation => _pendingRoute != null;

  /// Clear pending navigation
  void clearPendingNavigation() {
    _pendingRoute = null;
    debugPrint('NavigationService: Cleared pending navigation');
  }
}
