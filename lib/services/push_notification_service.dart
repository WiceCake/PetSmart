import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/services/navigation_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isInitialized = false;

  /// Initialize the push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('PushNotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('PushNotificationService: Error initializing: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/petsmart');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'petsmart_notifications',
        'PetSmart Notifications',
        description: 'Notifications from PetSmart app',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        debugPrint('PushNotificationService: Notification permission denied');
      }
    } else if (Platform.isIOS) {
      final bool? result = await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      if (result != true) {
        debugPrint('PushNotificationService: iOS notification permission denied');
      }
    }
  }



  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('PushNotificationService: Notification tapped: ${response.payload}');

    // Check if user is authenticated
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // User is not authenticated, set pending navigation
      debugPrint('PushNotificationService: User not authenticated, setting pending navigation');
      NavigationService().setPendingNavigation('notifications');
      return;
    }

    // User is authenticated, handle navigation immediately
    NavigationService().handleNotificationTap(response.payload);
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'petsmart_notifications',
      'PetSmart Notifications',
      channelDescription: 'Notifications from PetSmart app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/petsmart',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show chat notification
  Future<void> showChatNotification({
    required String title,
    required String body,
    String? conversationId,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'petsmart_chat',
      'PetSmart Chat',
      channelDescription: 'Chat messages from PetSmart support',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/petsmart',
      category: AndroidNotificationCategory.message,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'CHAT_CATEGORY',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = conversationId != null
        ? 'chat:$conversationId'
        : 'chat';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    await showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from PetSmart!',
      payload: 'test',
    );
  }

  /// Send test chat notification
  Future<void> sendTestChatNotification() async {
    await showChatNotification(
      title: 'New Message',
      body: 'You have a new message from customer support!',
      conversationId: 'test-conversation-id',
    );
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}
