class NotificationPreference {
  final String id;
  final String userId;
  final String type;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool inAppEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreference({
    required this.id,
    required this.userId,
    required this.type,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.inAppEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'in_app_enabled': inAppEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationPreference copyWith({
    String? id,
    String? userId,
    String? type,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? inAppEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Default notification preferences for new users
class DefaultNotificationPreferences {
  static List<Map<String, dynamic>> get defaults => [
    {
      'type': 'appointment',
      'push_enabled': true,
      'email_enabled': true,
      'in_app_enabled': true,
    },
    {
      'type': 'order',
      'push_enabled': true,
      'email_enabled': true,
      'in_app_enabled': true,
    },
    {
      'type': 'messages',
      'push_enabled': true,
      'email_enabled': false,
      'in_app_enabled': true,
    },
    {
      'type': 'pet',
      'push_enabled': true,
      'email_enabled': false,
      'in_app_enabled': true,
    },
    {
      'type': 'system',
      'push_enabled': true,
      'email_enabled': false,
      'in_app_enabled': true,
    },
  ];
}
