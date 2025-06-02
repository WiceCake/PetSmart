import 'package:intl/intl.dart';

/// Model representing a chat message
class ChatMessage {
  final String id;
  final String? conversationId;
  final String senderId;
  final String? receiverId;
  final String message;
  final MessageType messageType;
  final bool readStatus;
  final String? attachmentUrl;
  final bool isFromUser;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? sentAt;

  const ChatMessage({
    required this.id,
    this.conversationId,
    required this.senderId,
    this.receiverId,
    required this.message,
    required this.messageType,
    required this.readStatus,
    this.attachmentUrl,
    required this.isFromUser,
    required this.createdAt,
    this.updatedAt,
    this.sentAt,
  });

  /// Create ChatMessage from Supabase JSON response
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle both enhanced schema and basic schema
    final messageContent = json['message_content'] as String? ?? json['message'] as String? ?? '';
    final senderType = json['sender_type'] as String?;

    // Fix message alignment: Properly determine if message is from user
    bool isFromUser;
    if (senderType != null) {
      // Enhanced schema: use sender_type field
      isFromUser = senderType == 'user';
    } else if (json.containsKey('is_from_user')) {
      // Basic schema: use is_from_user field
      isFromUser = json['is_from_user'] as bool;
    } else {
      // Fallback: compare sender_id with current user (this should not happen in normal flow)
      // Default to false (admin message) to prevent all messages appearing on right side
      isFromUser = false;
    }

    final readStatus = json['is_read'] as bool? ?? json['read_status'] as bool? ?? false;

    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String?,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String?,
      message: messageContent,
      messageType: MessageType.fromString(json['message_type'] as String? ?? 'text'),
      readStatus: readStatus,
      attachmentUrl: json['attachment_url'] as String?,
      isFromUser: isFromUser,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
    );
  }

  /// Convert ChatMessage to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType.value,
      'read_status': readStatus,
      'attachment_url': attachmentUrl,
      'is_from_user': isFromUser,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
    };
  }

  /// Create a copy of this message with updated fields
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? message,
    MessageType? messageType,
    bool? readStatus,
    String? attachmentUrl,
    bool? isFromUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      readStatus: readStatus ?? this.readStatus,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      isFromUser: isFromUser ?? this.isFromUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  /// Get formatted timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final messageTime = createdAt;
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('h:mm a').format(messageTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE h:mm a').format(messageTime);
    } else {
      return DateFormat('MMM d, h:mm a').format(messageTime);
    }
  }

  /// Get detailed timestamp for message details
  String get detailedTimestamp {
    return DateFormat('MMM d, yyyy h:mm a').format(createdAt);
  }

  /// Check if message has attachment
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  /// Check if message is text type
  bool get isTextMessage => messageType == MessageType.text;

  /// Check if message is image type
  bool get isImageMessage => messageType == MessageType.image;

  /// Check if message is file type
  bool get isFileMessage => messageType == MessageType.file;

  /// Get message status for display
  MessageStatus get status {
    if (readStatus) {
      return MessageStatus.read;
    } else if (sentAt != null) {
      return MessageStatus.delivered;
    } else {
      return MessageStatus.sent;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage{id: $id, senderId: $senderId, message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}, isFromUser: $isFromUser}';
  }
}

/// Enum for message types
enum MessageType {
  text,
  image,
  file;

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
    }
  }

  static MessageType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}

/// Enum for message status
enum MessageStatus {
  sent,
  delivered,
  read;

  String get displayText {
    switch (this) {
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
    }
  }
}
