import 'dart:convert';

enum NotificationType {
  orderUpdate,
  walletUpdate,
  profileUpdate,
  serverAlert,
  promotion,
}

extension NotificationTypeX on NotificationType {
  /// Stable string key used for serialisation. Decoupled from enum index so
  /// reordering enum values never corrupts stored notifications.
  String get key => name; // uses Dart's built-in enum.name (e.g. 'orderUpdate')
}

/// Reverse lookup: string → NotificationType, with a safe fallback.
NotificationType _typeFromString(String? value) {
  if (value == null) return NotificationType.serverAlert;
  return NotificationType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => NotificationType.serverAlert,
  );
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      // Serialise as a stable string name, not a fragile integer index.
      'type': type.key,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      // Store metadata as a nested map — no extra jsonEncode layer needed.
      'metadata': metadata,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      // Safe string lookup — immune to enum reordering.
      type: _typeFromString(map['type'] as String?),
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['isRead'] ?? false,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationItem.fromJson(String source) =>
      NotificationItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
