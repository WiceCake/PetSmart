import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Model representing a conversation between a user and admin
class Conversation {
  final String id;
  final String userId;
  final String? adminId;
  final String status;
  final String? subject;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.userId,
    this.adminId,
    required this.status,
    this.subject,
    this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Conversation from Supabase JSON response
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      adminId: json['assigned_admin_id'] as String?, // Updated field name to match database
      status: json['status'] as String? ?? 'active', // Default to active for new conversations
      subject: json['subject'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : DateTime.now(), // Handle null last_message_at
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Conversation to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'assigned_admin_id': adminId, // Updated field name to match database
      'status': status,
      'subject': subject,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this conversation with updated fields
  Conversation copyWith({
    String? id,
    String? userId,
    String? adminId,
    String? status,
    String? subject,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      status: status ?? this.status,
      subject: subject ?? this.subject,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if conversation is active
  bool get isActive => status == 'active';

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Get formatted last message time for display
  String get formattedLastMessageTime {
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(lastMessageAt);
    }
  }

  /// Get conversation title for display
  String get title => subject?.isNotEmpty == true ? subject! : 'Customer Support';

  /// Get conversation subtitle for display
  String get subtitle {
    if (hasUnreadMessages) {
      return '$unreadCount new message${unreadCount > 1 ? 's' : ''}';
    }

    switch (status.toLowerCase()) {
      case 'active':
        return lastMessage?.isNotEmpty == true ? lastMessage! : 'Tap to continue conversation';
      case 'completed':
        return 'Conversation completed - Tap to view';
      case 'pending':
        return 'Waiting for support response';
      case 'resolved':
        return 'Conversation resolved - Tap to reopen';
      default:
        return 'Tap to continue conversation';
    }
  }

  /// Check if conversation is completed
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// Check if conversation is resolved (completed or closed)
  bool get isResolved => status.toLowerCase() == 'completed' || status.toLowerCase() == 'resolved' || status.toLowerCase() == 'closed';

  /// Check if conversation is pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if user can send messages
  bool get canSendMessages => status.toLowerCase() == 'active';

  /// Get status display text
  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'archived':
        return 'Archived';
      default:
        return 'Unknown';
    }
  }

  /// Get status color for UI display
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF3F51B5); // Blue for active
      case 'completed':
        return const Color(0xFF4CAF50); // Green for completed
      case 'pending':
        return const Color(0xFFFF9800); // Orange for pending
      case 'resolved':
        return const Color(0xFF4CAF50); // Green for resolved
      case 'closed':
        return const Color(0xFF757575); // Grey for closed
      case 'archived':
        return const Color(0xFF9E9E9E); // Light grey for archived
      default:
        return const Color(0xFF3F51B5); // Default blue
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Conversation{id: $id, userId: $userId, status: $status, unreadCount: $unreadCount}';
  }
}

/// Enum for conversation status
enum ConversationStatus {
  active,
  completed,
  closed,
  archived;

  String get value {
    switch (this) {
      case ConversationStatus.active:
        return 'active';
      case ConversationStatus.completed:
        return 'completed';
      case ConversationStatus.closed:
        return 'closed';
      case ConversationStatus.archived:
        return 'archived';
    }
  }

  static ConversationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ConversationStatus.active;
      case 'completed':
        return ConversationStatus.completed;
      case 'closed':
        return ConversationStatus.closed;
      case 'archived':
        return ConversationStatus.archived;
      default:
        return ConversationStatus.active;
    }
  }
}
