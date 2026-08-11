class NotificationPreferenceModel {
  NotificationPreferenceModel({
    required this.outfitReminders,
    required this.laundryReminders,
    required this.tripReminders,
    required this.packingReminders,
    required this.wearHistoryReminders,
    required this.wardrobeReminders,
    required this.aiStylistReminders,
    required this.subscriptionReminders,
    required this.premiumExpiryReminders,
    required this.smartReminders,
    required this.adminAnnouncements,
    required this.inAppEnabled,
    required this.localEnabled,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.timezone,
  });

  final bool outfitReminders;
  final bool laundryReminders;
  final bool tripReminders;
  final bool packingReminders;
  final bool wearHistoryReminders;
  final bool wardrobeReminders;
  final bool aiStylistReminders;
  final bool subscriptionReminders;
  final bool premiumExpiryReminders;
  final bool smartReminders;
  final bool adminAnnouncements;
  final bool inAppEnabled;
  final bool localEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String timezone;

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    bool b(String key, [bool fallback = true]) => json[key] as bool? ?? fallback;
    return NotificationPreferenceModel(
      outfitReminders: b('outfitReminders'),
      laundryReminders: b('laundryReminders'),
      tripReminders: b('tripReminders'),
      packingReminders: b('packingReminders'),
      wearHistoryReminders: b('wearHistoryReminders'),
      wardrobeReminders: b('wardrobeReminders'),
      aiStylistReminders: b('aiStylistReminders'),
      subscriptionReminders: b('subscriptionReminders'),
      premiumExpiryReminders: b('premiumExpiryReminders'),
      smartReminders: b('smartReminders'),
      adminAnnouncements: b('adminAnnouncements'),
      inAppEnabled: b('inAppEnabled'),
      localEnabled: b('localEnabled'),
      quietHoursEnabled: b('quietHoursEnabled', false),
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '07:00',
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() => {
    'outfitReminders': outfitReminders,
    'laundryReminders': laundryReminders,
    'tripReminders': tripReminders,
    'packingReminders': packingReminders,
    'wearHistoryReminders': wearHistoryReminders,
    'wardrobeReminders': wardrobeReminders,
    'aiStylistReminders': aiStylistReminders,
    'subscriptionReminders': subscriptionReminders,
    'premiumExpiryReminders': premiumExpiryReminders,
    'smartReminders': smartReminders,
    'adminAnnouncements': adminAnnouncements,
    'inAppEnabled': inAppEnabled,
    'localEnabled': localEnabled,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
    'timezone': timezone,
  };

  NotificationPreferenceModel copyWith(Map<String, dynamic> changes) {
    final merged = {...toJson(), ...changes};
    return NotificationPreferenceModel.fromJson(merged);
  }
}
