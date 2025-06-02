import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pet_smart/models/chat_message.dart';
import 'package:pet_smart/models/conversation.dart';
import 'package:pet_smart/services/chat_service.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';
import 'package:pet_smart/pages/messages/widgets/message_bubble.dart';
import 'package:pet_smart/pages/messages/widgets/typing_indicator.dart';
import 'package:pet_smart/pages/messages/widgets/chat_input.dart';
import 'package:pet_smart/pages/messages/new_conversation.dart';
import 'package:pet_smart/services/unread_message_service.dart';

// Enhanced color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);     // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5);   // Secondary blue
const Color backgroundColor = Color(0xFFF8F9FA); // Light background
const Color textPrimary = Color(0xFF222222);     // Primary text
const Color textSecondary = Color(0xFF666666);   // Secondary text

class DirectChatAdminPage extends StatefulWidget {
  final String? conversationId;
  final bool showBackButton;

  const DirectChatAdminPage({
    super.key,
    this.conversationId,
    this.showBackButton = true,
  });

  @override
  State<DirectChatAdminPage> createState() => _DirectChatAdminPageState();
}

class _DirectChatAdminPageState extends State<DirectChatAdminPage> {
  final ChatService _chatService = ChatService();
  final UnreadMessageService _unreadMessageService = UnreadMessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  Conversation? _conversation;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<bool>? _typingSubscription;
  StreamSubscription<Conversation?>? _conversationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _conversationSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.dispose(); // Properly dispose ChatService
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      setState(() => _isLoading = true);

      // Initialize chat service
      await _chatService.initialize();

      // Get or create conversation
      if (widget.conversationId != null) {
        // Load existing conversation by ID
        _conversation = await _chatService.getConversationById(widget.conversationId!);
        if (_conversation != null) {
          debugPrint('Chat initialized with conversation: ${_conversation!.id}');
          _chatService.setCurrentConversationId(_conversation!.id);
          await _loadConversation(_conversation!.id);
        } else {
          debugPrint('Failed to load conversation: ${widget.conversationId}');
          if (mounted) {
            EnhancedToasts.showError(
              context,
              'Failed to load conversation. Please try again.',
            );
          }
          return;
        }
      } else {
        // Try to get existing active conversation
        _conversation = await _chatService.getOrCreateConversation();
        if (_conversation != null) {
          debugPrint('Chat initialized with conversation: ${_conversation!.id}');
          _chatService.setCurrentConversationId(_conversation!.id);
          await _loadConversation(_conversation!.id);
        } else {
          debugPrint('No active conversation found, user needs to create one');
          if (mounted) {
            // Navigate to new conversation page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const NewConversationPage(),
              ),
            );
          }
          return;
        }
      }

      if (_conversation != null) {
        // Subscribe to real-time updates (only if enhanced schema is available)
        try {
          await _chatService.subscribeToConversation(_conversation!.id);
          _setupSubscriptions();

          // Mark messages as read
          await _chatService.markMessagesAsRead(_conversation!.id);
          // Update unread count
          await _unreadMessageService.markConversationAsRead(_conversation!.id);
        } catch (e) {
          debugPrint('Real-time features not available: $e');
          // Continue without real-time features
        }
      }

      debugPrint('Chat initialization completed successfully');

    } catch (e) {
      debugPrint('Error initializing chat: $e');
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'Chat system is starting up. You can still send messages.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    try {
      final messages = await _chatService.loadMessages(conversationId);
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading conversation: $e');
    }
  }

  void _setupSubscriptions() {
    // Subscribe to messages updates
    _messagesSubscription = _chatService.messagesStream.listen(
      (messages) {
        if (mounted) {
          // Only update if the message count is different or if we have new messages
          // This prevents overwriting our immediate UI updates
          if (messages.length != _messages.length ||
              (messages.isNotEmpty && _messages.isNotEmpty &&
               messages.last.id != _messages.last.id)) {
            setState(() {
              _messages = messages;
            });
            _scrollToBottom();
          }

          // Mark new messages as read
          if (_conversation != null) {
            _chatService.markMessagesAsRead(_conversation!.id);
            _unreadMessageService.markConversationAsRead(_conversation!.id);
          }
        }
      },
      onError: (error) {
        debugPrint('Messages stream error: $error');
      },
    );

    // Subscribe to typing indicator
    _typingSubscription = _chatService.typingStream.listen(
      (isTyping) {
        if (mounted) {
          setState(() {
            _isTyping = isTyping;
          });
        }
      },
      onError: (error) {
        debugPrint('Typing stream error: $error');
      },
    );

    // Subscribe to conversation updates
    _conversationSubscription = _chatService.currentConversationStream.listen(
      (updatedConversation) {
        if (mounted) {
          debugPrint('DirectChatAdminPage: Conversation stream update received');
          debugPrint('DirectChatAdminPage: Updated conversation: ${updatedConversation?.id} - Status: ${updatedConversation?.status}');
          debugPrint('DirectChatAdminPage: Current conversation: ${_conversation?.id} - Status: ${_conversation?.status}');

          if (updatedConversation != null) {
            setState(() {
              _conversation = updatedConversation;
            });
            debugPrint('DirectChatAdminPage: UI updated with new conversation status: ${updatedConversation.status}');
          } else {
            // Handle conversation deletion
            debugPrint('DirectChatAdminPage: Conversation was deleted, navigating back');
            Navigator.of(context).pop();
          }
        }
      },
      onError: (error) {
        debugPrint('DirectChatAdminPage: Conversation stream error: $error');
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendTextMessage(String message) async {
    debugPrint('_sendTextMessage called with: $message');
    debugPrint('_conversation: $_conversation');
    debugPrint('_isSending: $_isSending');

    if (_conversation == null) {
      debugPrint('No conversation available, trying to create one...');
      _conversation = await _chatService.getOrCreateConversation();
      if (_conversation == null) {
        debugPrint('Failed to create conversation');
        if (mounted) {
          EnhancedToasts.showError(
            context,
            'Failed to start conversation. Please try again.',
          );
        }
        return;
      }
    }

    if (_isSending) {
      debugPrint('Already sending a message, ignoring...');
      return;
    }

    try {
      setState(() => _isSending = true);
      debugPrint('Sending message to conversation: ${_conversation!.id}');
      debugPrint('DirectChatAdminPage: _conversation before sendMessage: $_conversation');
      debugPrint('DirectChatAdminPage: _conversation status: ${_conversation?.status}');
      debugPrint('DirectChatAdminPage: About to call sendMessage with currentConversation: $_conversation');

      final sentMessage = await _chatService.sendMessage(
        message,
        conversationId: _conversation!.id,
        currentConversation: _conversation,
      );

      debugPrint('Message sent successfully: $sentMessage');

      if (sentMessage != null && mounted) {
        // Immediately add the message to the UI for instant feedback
        setState(() {
          _messages.add(sentMessage);
        });

        // Clear the input and scroll to bottom
        _messageController.clear();
        _scrollToBottom();

        EnhancedToasts.showMessageSent(context);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'Failed to send message. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }



  void _onTypingChanged(bool isTyping) {
    if (_conversation != null) {
      _chatService.updateTypingIndicator(_conversation!.id, isTyping);
    }
  }

  Future<void> _refreshMessages() async {
    debugPrint('DirectChatAdminPage: Refreshing messages and conversation status');
    if (_conversation != null) {
      // Reload the entire conversation (messages + status)
      await _loadConversation(_conversation!.id);

      // Also manually refresh the conversation status
      final updatedConversation = await _chatService.getConversationById(_conversation!.id);
      if (mounted && updatedConversation != null) {
        debugPrint('DirectChatAdminPage: Manual refresh - Updated conversation status: ${updatedConversation.status}');
        setState(() {
          _conversation = updatedConversation;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: widget.showBackButton ? IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: primaryBlue,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
        automaticallyImplyLeading: widget.showBackButton,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversation?.title ?? 'Customer Support',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _conversation?.isCompleted == true
                              ? 'Conversation completed'
                              : _conversation?.isResolved == true
                                  ? 'Conversation resolved'
                                  : 'We\'re here to help',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_conversation != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _conversation!.statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _conversation!.statusColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _conversation!.statusDisplayText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _conversation!.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: primaryBlue,
            ),
            onPressed: _refreshMessages,
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Show completed conversation banner
                if (_conversation?.isCompleted == true)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: const Color(0xFF4CAF50),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This conversation has been completed by our support team.',
                                style: TextStyle(
                                  color: const Color(0xFF4CAF50),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NewConversationPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Start New Conversation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                // Show resolved conversation banner
                else if (_conversation?.isResolved == true)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: const Color(0xFF4CAF50),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This conversation has been resolved. Send a message to reopen it.',
                            style: TextStyle(
                              color: const Color(0xFF4CAF50),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshMessages,
                    color: primaryBlue,
                    child: _buildMessagesList(),
                  ),
                ),
                TypingIndicator(
                  isVisible: _isTyping,
                  userName: 'Support',
                ),
                // Only show chat input if conversation is not completed
                if (_conversation?.isCompleted != true)
                  ChatInput(
                    controller: _messageController,
                    onSendMessage: _sendTextMessage,
                    onTypingChanged: _onTypingChanged,
                    isEnabled: !_isSending, // Always enabled when not sending
                    hintText: _conversation?.isResolved == true
                        ? 'Send a message to reopen conversation...'
                        : 'Type your message...',
                  ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: primaryBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading chat...',
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showTimestamp = index == 0 ||
            _messages[index - 1].createdAt.difference(message.createdAt).inMinutes.abs() > 5;

        return MessageBubble(
          message: message,
          showTimestamp: showTimestamp,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start a conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send us a message and we\'ll get back to you as soon as possible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }


}