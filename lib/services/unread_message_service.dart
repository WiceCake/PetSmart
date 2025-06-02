import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to track unread message counts across the app
class UnreadMessageService {
  static final UnreadMessageService _instance = UnreadMessageService._internal();
  factory UnreadMessageService() => _instance;
  UnreadMessageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream controller for unread count updates
  final StreamController<int> _unreadCountController = StreamController<int>.broadcast();
  
  // Current unread count
  int _unreadCount = 0;
  
  // Real-time subscription
  RealtimeChannel? _subscription;
  
  /// Get stream of unread count updates
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  
  /// Get current unread count
  int get unreadCount => _unreadCount;

  /// Initialize the service and start listening for updates
  Future<void> initialize() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Load initial unread count
      await _loadUnreadCount();

      // Subscribe to real-time updates
      await _setupRealtimeSubscription();

      debugPrint('UnreadMessageService: Initialized with count: $_unreadCount');
    } catch (e) {
      debugPrint('UnreadMessageService: Error initializing: $e');
    }
  }

  /// Load current unread count from database
  Future<void> _loadUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get total unread count from all user's conversations
      final response = await _supabase
          .from('conversations')
          .select('unread_count')
          .eq('user_id', userId);

      int totalUnread = 0;
      for (final conversation in response) {
        totalUnread += (conversation['unread_count'] as int? ?? 0);
      }

      _updateUnreadCount(totalUnread);
    } catch (e) {
      debugPrint('UnreadMessageService: Error loading unread count: $e');
    }
  }

  /// Setup real-time subscription for unread count updates
  Future<void> _setupRealtimeSubscription() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Unsubscribe from previous subscription
      await _subscription?.unsubscribe();

      // Subscribe to conversations table changes
      _subscription = _supabase
          .channel('unread_messages:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversations',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) => _handleConversationChange(payload),
          )
          .subscribe();

      debugPrint('UnreadMessageService: Subscribed to real-time updates');
    } catch (e) {
      debugPrint('UnreadMessageService: Error setting up subscription: $e');
    }
  }

  /// Handle conversation changes from real-time subscription
  void _handleConversationChange(PostgresChangePayload payload) {
    debugPrint('UnreadMessageService: Conversation change detected');
    // Reload unread count when conversations change
    _loadUnreadCount();
  }

  /// Update unread count and notify listeners
  void _updateUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
      _unreadCountController.add(_unreadCount);
      debugPrint('UnreadMessageService: Updated unread count to: $_unreadCount');
    }
  }

  /// Mark messages as read for a conversation
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _supabase.rpc('mark_messages_as_read', params: {
        'conversation_uuid': conversationId,
      });
      
      // Reload unread count after marking as read
      await _loadUnreadCount();
    } catch (e) {
      debugPrint('UnreadMessageService: Error marking conversation as read: $e');
    }
  }

  /// Refresh unread count manually
  Future<void> refresh() async {
    await _loadUnreadCount();
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.unsubscribe();
    _unreadCountController.close();
    debugPrint('UnreadMessageService: Disposed');
  }
}
