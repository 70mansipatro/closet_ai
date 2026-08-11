class AdminAnnouncement {
  const AdminAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.targetAudience,
    required this.status,
    required this.scheduledAt,
    required this.recipientCount,
  });

  factory AdminAnnouncement.fromJson(Map<String, dynamic> json) {
    return AdminAnnouncement(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'normal',
      targetAudience: json['targetAudience']?.toString() ?? 'all',
      status: json['status']?.toString() ?? 'scheduled',
      scheduledAt: json['scheduledAt']?.toString() ?? '',
      recipientCount: (json['recipientCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String title;
  final String message;
  final String priority;
  final String targetAudience;
  final String status;
  final String scheduledAt;
  final int recipientCount;
}

class AdminNotificationStats {
  const AdminNotificationStats({
    required this.total,
    required this.read,
    required this.unread,
    required this.readRate,
    required this.cancelled,
    required this.failed,
    required this.expired,
    required this.byType,
    required this.byDay,
  });

  factory AdminNotificationStats.fromJson(Map<String, dynamic> json) {
    return AdminNotificationStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      read: (json['read'] as num?)?.toInt() ?? 0,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      readRate: (json['readRate'] as num?)?.toDouble() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      expired: (json['expired'] as num?)?.toInt() ?? 0,
      byType: (json['byType'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      byDay: (json['byDay'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  final int total;
  final int read;
  final int unread;
  final double readRate;
  final int cancelled;
  final int failed;
  final int expired;
  final List<Map<String, dynamic>> byType;
  final List<Map<String, dynamic>> byDay;
}
