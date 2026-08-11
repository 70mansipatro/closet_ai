class ReminderModel {
  ReminderModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.enabled,
    required this.frequency,
    required this.scheduledTime,
    required this.daysOfWeek,
    required this.date,
    required this.priority,
    required this.snoozeMinutes,
    required this.smartEnabled,
    required this.nextTriggerAt,
    required this.lastTriggeredAt,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final bool enabled;
  final String frequency;
  final String scheduledTime;
  final List<int> daysOfWeek;
  final DateTime? date;
  final String priority;
  final int snoozeMinutes;
  final bool smartEnabled;
  final DateTime? nextTriggerAt;
  final DateTime? lastTriggeredAt;

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'CUSTOM',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      frequency: json['frequency'] as String? ?? 'once',
      scheduledTime: json['scheduledTime'] as String? ?? '',
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      priority: json['priority'] as String? ?? 'normal',
      snoozeMinutes: (json['snoozeMinutes'] as num?)?.toInt() ?? 0,
      smartEnabled: json['smartEnabled'] as bool? ?? false,
      nextTriggerAt: json['nextTriggerAt'] != null ? DateTime.tryParse(json['nextTriggerAt'].toString()) : null,
      lastTriggeredAt: json['lastTriggeredAt'] != null ? DateTime.tryParse(json['lastTriggeredAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'enabled': enabled,
      'frequency': frequency,
      if (scheduledTime.isNotEmpty) 'scheduledTime': scheduledTime,
      if (daysOfWeek.isNotEmpty) 'daysOfWeek': daysOfWeek,
      if (date != null) 'date': date!.toIso8601String(),
      'priority': priority,
      'snoozeMinutes': snoozeMinutes,
      'smartEnabled': smartEnabled,
    };
  }
}

const List<String> reminderTypes = [
  'CUSTOM',
  'OUTFIT_REMINDER',
  'LAUNDRY_REMINDER',
  'TRIP_REMINDER',
  'PACKING_REMINDER',
  'WEAR_HISTORY_REMINDER',
  'WARDROBE_REMINDER',
  'AI_STYLIST_REMINDER',
  'SUBSCRIPTION_REMINDER',
];

const List<String> reminderFrequencies = ['once', 'daily', 'weekly', 'monthly', 'smart'];
const List<String> reminderPriorities = ['low', 'normal', 'high', 'urgent'];
