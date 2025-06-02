import 'package:flutter/material.dart';
import 'package:pet_smart/models/chat_message.dart';

// Enhanced color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);     // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5);   // Secondary blue
const Color backgroundColor = Color(0xFFF8F9FA); // Light background
const Color userMessageColor = Color(0xFF3F51B5); // User message background
const Color adminMessageColor = Colors.white;    // Admin message background
const Color textPrimary = Color(0xFF222222);     // Primary text
const Color textSecondary = Color(0xFF666666);   // Secondary text
const Color successGreen = Color(0xFF4CAF50);    // Success green

/// Widget for displaying individual chat message bubbles
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: message.isFromUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isFromUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isFromUser) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: _buildMessageContainer(context),
              ),
              if (message.isFromUser) ...[
                const SizedBox(width: 8),
                _buildMessageStatus(),
              ],
            ],
          ),
          if (showTimestamp) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(
                left: message.isFromUser ? 0 : 48,
                right: message.isFromUser ? 24 : 0,
              ),
              child: Text(
                message.formattedTime,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: message.isFromUser ? TextAlign.end : TextAlign.start,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build avatar for admin messages
  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.support_agent_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Build main message container
  Widget _buildMessageContainer(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: message.isFromUser ? userMessageColor : adminMessageColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.isFromUser ? 16 : 4),
          bottomRight: Radius.circular(message.isFromUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildMessageContent(context),
    );
  }

  /// Build message content - only text messages supported
  Widget _buildMessageContent(BuildContext context) {
    return _buildTextMessage();
  }

  /// Build text message content
  Widget _buildTextMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        message.message,
        style: TextStyle(
          color: message.isFromUser ? Colors.white : textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
      ),
    );
  }



  /// Build message status indicator for user messages
  Widget _buildMessageStatus() {
    if (!message.isFromUser) return const SizedBox.shrink();

    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sent:
        icon = Icons.check_rounded;
        color = textSecondary;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all_rounded;
        color = textSecondary;
        break;
      case MessageStatus.read:
        icon = Icons.done_all_rounded;
        color = successGreen;
        break;
    }

    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }
}
