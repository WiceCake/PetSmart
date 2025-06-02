import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pet_smart/models/conversation.dart';
import 'package:pet_smart/services/chat_service.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';
import 'package:pet_smart/pages/messages/direct_chat_admin.dart';

// Enhanced color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);     // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5);   // Secondary blue
const Color backgroundColor = Color(0xFFF8F9FA); // Light background
const Color textPrimary = Color(0xFF222222);     // Primary text
const Color textSecondary = Color(0xFF666666);   // Secondary text
const Color successGreen = Color(0xFF4CAF50);    // Success green

/// Page for displaying list of conversations
class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  StreamSubscription<List<Conversation>>? _conversationsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeConversations();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeConversations() async {
    try {
      setState(() => _isLoading = true);

      // Initialize chat service
      await _chatService.initialize();

      // Load conversations
      await _loadConversations();

      // Subscribe to real-time updates
      _setupSubscriptions();

    } catch (e) {
      debugPrint('Error initializing conversations: $e');
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'Failed to load conversations. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _chatService.loadConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  void _setupSubscriptions() {
    _conversationsSubscription = _chatService.conversationsStream.listen(
      (conversations) {
        if (mounted) {
          setState(() {
            _conversations = conversations;
          });
        }
      },
      onError: (error) {
        debugPrint('Conversations stream error: $error');
      },
    );
  }

  Future<void> _refreshConversations() async {
    await _loadConversations();
  }

  void _openConversation(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DirectChatAdminPage(
          conversationId: conversation.id,
        ),
      ),
    );
  }

  void _startNewConversation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DirectChatAdminPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Messages',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: primaryBlue,
            ),
            onPressed: _refreshConversations,
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _refreshConversations,
              color: primaryBlue,
              child: _conversations.isEmpty
                  ? _buildEmptyState()
                  : _buildConversationsList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        backgroundColor: primaryBlue,
        child: const Icon(
          Icons.chat_rounded,
          color: Colors.white,
        ),
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
            'Loading conversations...',
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 50,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start a conversation with our support team to get help with your questions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Start Conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (conversation.hasUnreadMessages)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: successGreen,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      conversation.unreadCount > 9 ? '9+' : '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: conversation.statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: conversation.statusColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                conversation.statusDisplayText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: conversation.statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              conversation.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: conversation.hasUnreadMessages ? successGreen : textSecondary,
                fontWeight: conversation.hasUnreadMessages ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              conversation.formattedLastMessageTime,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: textSecondary,
        ),
        onTap: () => _openConversation(conversation),
      ),
    );
  }
}
