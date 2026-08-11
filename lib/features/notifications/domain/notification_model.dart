import 'package:flutter/material.dart';

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.body,
    required this.priority,
    required this.status,
    required this.isRead,
    required this.readAt,
    required this.sourceType,
    required this.sourceId,
    required this.actionType,
    required this.actionRoute,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String body;
  final String priority;
  final String status;
  final bool isRead;
  final DateTime? readAt;
  final String sourceType;
  final String? sourceId;
  final String actionType;
  final String actionRoute;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'SYSTEM',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      body: json['body'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'sent',
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      sourceType: json['sourceType'] as String? ?? '',
      sourceId: json['sourceId']?.toString(),
      actionType: json['actionType'] as String? ?? '',
      actionRoute: json['actionRoute'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationTypeInfo {
  const NotificationTypeInfo(this.label, this.icon);
  final String label;
  final IconData icon;
}

const Map<String, NotificationTypeInfo> notificationTypeInfo = {
  'OUTFIT_REMINDER': NotificationTypeInfo('Outfit', Icons.checkroom_outlined),
  'LAUNDRY_REMINDER': NotificationTypeInfo('Laundry', Icons.local_laundry_service_outlined),
  'TRIP_REMINDER': NotificationTypeInfo('Trip', Icons.flight_takeoff_outlined),
  'PACKING_REMINDER': NotificationTypeInfo('Packing', Icons.luggage_outlined),
  'WEAR_HISTORY_REMINDER': NotificationTypeInfo('Wear history', Icons.history_outlined),
  'WARDROBE_REMINDER': NotificationTypeInfo('Wardrobe', Icons.door_sliding_outlined),
  'AI_STYLIST_REMINDER': NotificationTypeInfo('AI Stylist', Icons.auto_awesome_outlined),
  'SUBSCRIPTION_REMINDER': NotificationTypeInfo('Subscription', Icons.workspace_premium_outlined),
  'PREMIUM_EXPIRY': NotificationTypeInfo('Premium', Icons.workspace_premium_outlined),
  'SYSTEM': NotificationTypeInfo('System', Icons.info_outline),
  'ADMIN_ANNOUNCEMENT': NotificationTypeInfo('Announcement', Icons.campaign_outlined),
  'SMART_REMINDER': NotificationTypeInfo('Smart reminder', Icons.lightbulb_outline),
};

NotificationTypeInfo notificationInfoFor(String type) =>
    notificationTypeInfo[type] ?? const NotificationTypeInfo('Notification', Icons.notifications_outlined);

/// Maps a reminder/notification `type` to the in-app route it should open.
/// Kept alongside the backend's own mapping (notificationScheduler.js) so a
/// locally-scheduled notification tap and a server notification tap behave
/// the same way.
const Map<String, String> notificationActionRoutes = {
  'OUTFIT_REMINDER': '/calendar',
  'LAUNDRY_REMINDER': '/laundry',
  'TRIP_REMINDER': '/trips',
  'PACKING_REMINDER': '/packing',
  'WEAR_HISTORY_REMINDER': '/history/wear',
  'WARDROBE_REMINDER': '/wardrobe',
  'AI_STYLIST_REMINDER': '/ai/stylist',
  'SUBSCRIPTION_REMINDER': '/subscription',
  'PREMIUM_EXPIRY': '/subscription',
  'ADMIN_ANNOUNCEMENT': '/notifications',
};

String routeForNotificationType(String type) => notificationActionRoutes[type] ?? '/notifications';
