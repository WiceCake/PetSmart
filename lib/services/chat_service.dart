import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/models/chat_message.dart';
import 'package:pet_smart/models/conversation.dart';
import 'package:pet_smart/config/app_config.dart';

/// Service for managing chat functionality with real-time messaging
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for real-time updates
  final StreamController<List<ChatMessage>> _messagesController =
      StreamController<List<ChatMessage>>.broadcast();
  final StreamController<List<Conversation>> _conversationsController =
      StreamController<List<Conversation>>.broadcast();
  final StreamController<Conversation?> _currentConversationController =
      StreamController<Conversation?>.broadcast();
  final StreamController<bool> _typingController =
      StreamController<bool>.broadcast();

  // Subscriptions for cleanup
  RealtimeChannel? _messagesSubscription;
  RealtimeChannel? _conversationsSubscription;
  RealtimeChannel? _typingSubscription;

  // Current conversation tracking
  String? _currentConversationId;
  Timer? _typingTimer;

  /// Get messages stream for real-time updates
  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;

  /// Get conversations stream for real-time updates
  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;

  /// Get current conversation stream for real-time updates
  Stream<Conversation?> get currentConversationStream => _currentConversationController.stream;

  /// Get typing indicator stream
  Stream<bool> get typingStream => _typingController.stream;

  /// Set the current conversation ID for real-time updates
  void setCurrentConversationId(String? conversationId) {
    _currentConversationId = conversationId;
    debugPrint('ChatService: Current conversation ID set to: $conversationId');
  }

  /// Initialize chat service
  Future<void> initialize() async {
    if (!AppConfig.isConfigured()) {
      debugPrint('ChatService: Supabase not configured, skipping initialization');
      return;
    }

    try {
      await _setupRealtimeSubscriptions();
      debugPrint('ChatService: Initialized successfully');
    } catch (e) {
      debugPrint('ChatService: Error initializing: $e');
    }
  }

  /// Setup real-time subscriptions for messages and conversations
  Future<void> _setupRealtimeSubscriptions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Subscribe to conversations changes
    _conversationsSubscription = _supabase
        .channel('conversations:$userId')
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

    debugPrint('ChatService: Subscribed to conversations');
  }

  /// Subscribe to messages for a specific conversation
  Future<void> subscribeToConversation(String conversationId) async {
    _currentConversationId = conversationId;

    // Unsubscribe from previous messages subscription
    await _messagesSubscription?.unsubscribe();

    // Subscribe to messages for this conversation
    _messagesSubscription = _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => _handleMessageChange(payload),
        )
        .subscribe();

    // Subscribe to typing indicators
    _typingSubscription = _supabase
        .channel('typing:$conversationId')
        .onPresenceSync((payload) => _handleTypingChange(payload))
        .subscribe();

    debugPrint('ChatService: Subscribed to conversation $conversationId');
  }

  /// Handle conversation changes from real-time subscription
  void _handleConversationChange(PostgresChangePayload payload) {
    debugPrint('ChatService: Conversation change: ${payload.eventType}');
    debugPrint('ChatService: Payload details - oldRecord: ${payload.oldRecord}, newRecord: ${payload.newRecord}');

    // Handle different types of changes
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    // Check if this affects the current conversation being viewed
    String? affectedConversationId;
    if (newRecord.containsKey('id')) {
      affectedConversationId = newRecord['id'] as String?;
    } else if (oldRecord.containsKey('id')) {
      affectedConversationId = oldRecord['id'] as String?;
    }

    if (_currentConversationId != null &&
        affectedConversationId == _currentConversationId) {

      debugPrint('ChatService: Current conversation affected - ID: $_currentConversationId');

      // Update the current conversation
      try {
        if (payload.eventType == PostgresChangeEvent.delete) {
          // Handle conversation deletion
          debugPrint('ChatService: Current conversation was deleted');
          if (!_currentConversationController.isClosed) {
            _currentConversationController.add(null);
          }
        } else {
          final updatedConversation = Conversation.fromJson(newRecord);
          debugPrint('ChatService: Current conversation updated - Status: ${updatedConversation.status}');

          // Only emit to stream if controller is not closed
          if (!_currentConversationController.isClosed) {
            _currentConversationController.add(updatedConversation);
            debugPrint('ChatService: Emitted updated conversation to stream');
          }
        }
      } catch (e) {
        debugPrint('ChatService: Error parsing updated conversation: $e');
      }
    }

    // Refresh conversations list for any change
    debugPrint('ChatService: Refreshing conversations list due to real-time change');
    loadConversations();
  }

  /// Handle message changes from real-time subscription
  void _handleMessageChange(PostgresChangePayload payload) {
    debugPrint('ChatService: Message change: ${payload.eventType} - ${payload.newRecord}');
    if (_currentConversationId != null) {
      // Add a small delay to ensure database consistency
      Future.delayed(const Duration(milliseconds: 100), () {
        loadMessages(_currentConversationId!);
      });
    }
  }

  /// Handle typing indicator changes
  void _handleTypingChange(dynamic payload) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Handle presence sync payload
      if (payload is Map<String, dynamic>) {
        final presences = payload['presences'] as Map<String, dynamic>?;
        if (presences != null) {
          // Check if admin is typing (anyone other than current user)
          bool isAdminTyping = false;
          for (final entry in presences.entries) {
            final presenceList = entry.value as List<dynamic>?;
            if (presenceList != null) {
              for (final presence in presenceList) {
                if (presence is Map<String, dynamic>) {
                  final presenceUserId = presence['user_id'] as String?;
                  final isTyping = presence['is_typing'] as bool? ?? false;
                  if (presenceUserId != userId && isTyping) {
                    isAdminTyping = true;
                    break;
                  }
                }
              }
              if (isAdminTyping) break;
            }
          }
          // Only add to stream if controller is not closed
          if (!_typingController.isClosed) {
            _typingController.add(isAdminTyping);
          }
        }
      }
    } catch (e) {
      debugPrint('ChatService: Error handling typing change: $e');
    }
  }

  /// Load conversations for current user
  Future<List<Conversation>> loadConversations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('conversations')
          .select()
          .eq('user_id', userId)
          .order('last_message_at', ascending: false);

      final conversations = (response as List)
          .map((json) => Conversation.fromJson(json))
          .toList();

      // Only add to stream if controller is not closed
      if (!_conversationsController.isClosed) {
        _conversationsController.add(conversations);
      }
      return conversations;
    } catch (e) {
      debugPrint('ChatService: Error loading conversations: $e');
      // Only add error to stream if controller is not closed
      if (!_conversationsController.isClosed) {
        _conversationsController.addError(e);
      }
      return [];
    }
  }

  /// Load messages for a specific conversation
  Future<List<ChatMessage>> loadMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      List<ChatMessage> messages = [];

      try {
        // Try enhanced schema first
        debugPrint('ChatService: Loading messages with enhanced schema for conversation: $conversationId');
        final response = await _supabase
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        messages = (response as List)
            .map((json) => ChatMessage.fromJson(json))
            .toList()
            .reversed
            .toList(); // Reverse to show oldest first

        debugPrint('ChatService: Loaded ${messages.length} messages with enhanced schema');
      } catch (e) {
        debugPrint('ChatService: Enhanced schema failed, trying basic schema: $e');

        // Fallback to basic schema - load all user messages
        final response = await _supabase
            .from('messages')
            .select()
            .or('sender_id.eq.$userId,receiver_id.eq.$userId')
            .order('sent_at', ascending: false)
            .range(offset, offset + limit - 1);

        messages = (response as List).map((json) {
          return ChatMessage(
            id: json['id'] as String,
            conversationId: conversationId,
            senderId: json['sender_id'] as String,
            receiverId: json['receiver_id'] as String?,
            message: json['message'] as String,
            messageType: MessageType.text,
            readStatus: false,
            isFromUser: json['sender_id'] == userId,
            createdAt: DateTime.parse(json['sent_at'] as String),
            sentAt: DateTime.parse(json['sent_at'] as String),
          );
        }).toList().reversed.toList(); // Reverse to show oldest first

        debugPrint('ChatService: Loaded ${messages.length} messages with basic schema');
      }

      // Only add to stream if controller is not closed
      if (!_messagesController.isClosed) {
        _messagesController.add(messages);
      }
      return messages;
    } catch (e) {
      debugPrint('ChatService: Error loading messages: $e');
      // Only add error to stream if controller is not closed
      if (!_messagesController.isClosed) {
        _messagesController.addError(e);
      }
      return [];
    }
  }

  /// Send a text message
  Future<ChatMessage?> sendMessage(String message, {String? conversationId, Conversation? currentConversation}) async {
    try {
      debugPrint('ChatService.sendMessage called with: "$message", conversationId: $conversationId');

      final userId = _supabase.auth.currentUser?.id;
      debugPrint('ChatService: Current user ID: $userId');

      if (userId == null) throw Exception('User not authenticated');

      if (message.trim().isEmpty) throw Exception('Message cannot be empty');
      if (message.length > 1000) throw Exception('Message too long (max 1000 characters)');

      // Check if we need to reopen a resolved conversation
      debugPrint('ChatService: Checking conversation status - conversationId: $conversationId, currentConversation: ${currentConversation?.status}');
      debugPrint('ChatService: Condition check - conversationId != null: ${conversationId != null}');
      debugPrint('ChatService: Condition check - currentConversation != null: ${currentConversation != null}');

      // If currentConversation is null but we have a conversationId, fetch the conversation from database
      Conversation? conversationToCheck = currentConversation;
      if (conversationId != null && currentConversation == null) {
        debugPrint('ChatService: currentConversation is null, fetching from database');
        conversationToCheck = await getConversationById(conversationId);
        debugPrint('ChatService: Fetched conversation from database: ${conversationToCheck?.status}');
      }

      debugPrint('ChatService: Condition check - status == resolved: ${conversationToCheck?.status == 'resolved'}');
      debugPrint('ChatService: Condition check - status == closed: ${conversationToCheck?.status == 'closed'}');

      if (conversationId != null && conversationToCheck != null &&
          (conversationToCheck.status == 'resolved' || conversationToCheck.status == 'closed')) {
        debugPrint('ChatService: Reopening resolved/closed conversation: $conversationId');
        await _reopenConversation(conversationId);
      } else {
        debugPrint('ChatService: Not reopening conversation - condition not met');
      }

      // Use enhanced schema with proper field mapping
      Map<String, dynamic> messageData = {
        'conversation_id': conversationId,
        'sender_id': userId,
        'sender_type': 'user', // Explicitly set sender type for users
        'message_content': message.trim(), // Use message_content field
        'message_type': 'text',
        'is_read': false, // New messages start as unread
      };

      debugPrint('ChatService: Sending message with enhanced schema: $messageData');

      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      debugPrint('ChatService: Enhanced schema insert response: $response');

      final chatMessage = ChatMessage.fromJson(response);
      debugPrint('ChatService: Message sent successfully: ${chatMessage.id}');
      return chatMessage;
    } catch (e) {
      debugPrint('ChatService: Error sending message: $e');
      rethrow;
    }
  }

  /// Reopen a resolved or closed conversation
  Future<void> _reopenConversation(String conversationId) async {
    try {
      debugPrint('ChatService: Reopening conversation: $conversationId');

      await _supabase
          .from('conversations')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      debugPrint('ChatService: Conversation reopened successfully');
    } catch (e) {
      debugPrint('ChatService: Error reopening conversation: $e');
      // Don't throw error, just log it - message sending should still work
    }
  }



  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await _supabase.rpc('mark_messages_as_read', params: {
        'conversation_uuid': conversationId,
      });
      debugPrint('ChatService: Messages marked as read');
    } catch (e) {
      debugPrint('ChatService: Error marking messages as read: $e');
    }
  }

  /// Update typing indicator
  Future<void> updateTypingIndicator(String conversationId, bool isTyping) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Cancel previous timer
      _typingTimer?.cancel();

      if (isTyping) {
        // Set typing indicator
        await _supabase
            .from('typing_indicators')
            .upsert({
              'conversation_id': conversationId,
              'user_id': userId,
              'is_typing': true,
              'last_typed_at': DateTime.now().toIso8601String(),
            });

        // Auto-clear typing indicator after 3 seconds
        _typingTimer = Timer(const Duration(seconds: 3), () {
          updateTypingIndicator(conversationId, false);
        });
      } else {
        // Clear typing indicator
        await _supabase
            .from('typing_indicators')
            .upsert({
              'conversation_id': conversationId,
              'user_id': userId,
              'is_typing': false,
              'last_typed_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      debugPrint('ChatService: Error updating typing indicator: $e');
    }
  }

  /// Get all conversations for the current user
  Future<List<Conversation>> getUserConversations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint('ChatService: Getting conversations for user: $userId');

      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            messages!inner(
              message_content,
              created_at
            )
          ''')
          .eq('user_id', userId)
          .order('last_message_at', ascending: false);

      final conversations = (response as List<dynamic>).map((json) {
        // Get the last message content for preview
        final messages = json['messages'] as List<dynamic>? ?? [];
        String? lastMessage;
        if (messages.isNotEmpty) {
          // Sort messages by created_at and get the latest
          messages.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
          lastMessage = messages.first['message_content'] as String?;
        }

        // Add last_message to the conversation data
        final conversationData = Map<String, dynamic>.from(json);
        conversationData['last_message'] = lastMessage;
        conversationData.remove('messages'); // Remove the messages array

        return Conversation.fromJson(conversationData);
      }).toList();

      debugPrint('ChatService: Found ${conversations.length} conversations');
      return conversations;
    } catch (e) {
      debugPrint('ChatService: Error getting conversations: $e');
      return [];
    }
  }

  /// Create a new conversation with subject
  Future<Conversation?> createConversation(String subject) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint('ChatService: Creating new conversation with subject: $subject');

      final newConversationData = {
        'user_id': userId,
        'subject': subject,
        'status': 'active',
        'unread_count': 0,
        'last_message_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('conversations')
          .insert(newConversationData)
          .select()
          .single();

      final conversation = Conversation.fromJson(response);
      debugPrint('ChatService: Created new conversation: ${conversation.id}');
      return conversation;
    } catch (e) {
      debugPrint('ChatService: Error creating conversation: $e');
      return null;
    }
  }

  /// Get conversation by ID
  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint('ChatService: Getting conversation by ID: $conversationId');

      final response = await _supabase
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .eq('user_id', userId) // Ensure user owns the conversation
          .single();

      final conversation = Conversation.fromJson(response);
      debugPrint('ChatService: Found conversation: ${conversation.id}');
      return conversation;
    } catch (e) {
      debugPrint('ChatService: Error getting conversation by ID: $e');
      return null;
    }
  }

  /// Get or create conversation for current user (for backward compatibility)
  Future<Conversation?> getOrCreateConversation() async {
    try {
      debugPrint('ChatService.getOrCreateConversation called');

      final userId = _supabase.auth.currentUser?.id;
      debugPrint('ChatService: Current user ID for conversation: $userId');

      if (userId == null) throw Exception('User not authenticated');

      // First, try to get an existing active conversation
      debugPrint('ChatService: Checking for existing active conversation');
      final existingResponse = await _supabase
          .from('conversations')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active') // Only get active conversations
          .order('created_at', ascending: false)
          .maybeSingle();

      debugPrint('ChatService: Existing conversation response: $existingResponse');

      if (existingResponse != null) {
        final conversation = Conversation.fromJson(existingResponse);
        debugPrint('ChatService: Found existing active conversation: ${conversation.id}');
        return conversation;
      }

      // If no active conversation exists, return null to prompt for subject
      debugPrint('ChatService: No active conversation found, user needs to create one');
      return null;
    } catch (e) {
      debugPrint('ChatService: Error getting conversation: $e');
      return null;
    }
  }

  /// Dispose of resources
  void dispose() {
    _messagesSubscription?.unsubscribe();
    _conversationsSubscription?.unsubscribe();
    _typingSubscription?.unsubscribe();
    _typingTimer?.cancel();

    _messagesController.close();
    _conversationsController.close();
    _currentConversationController.close();
    _typingController.close();

    debugPrint('ChatService: Disposed');
  }
}
