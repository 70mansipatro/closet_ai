class SmartReminderSettingModel {
  SmartReminderSettingModel({
    required this.enabled,
    required this.smartOutfit,
    required this.smartLaundry,
    required this.smartPacking,
    required this.smartTrip,
    required this.smartWardrobe,
    required this.smartWearHistory,
    required this.smartAIStylist,
    required this.maxDailyReminders,
    required this.minimumIntervalMinutes,
    required this.quietHoursEnabled,
  });

  final bool enabled;
  final bool smartOutfit;
  final bool smartLaundry;
  final bool smartPacking;
  final bool smartTrip;
  final bool smartWardrobe;
  final bool smartWearHistory;
  final bool smartAIStylist;
  final int maxDailyReminders;
  final int minimumIntervalMinutes;
  final bool quietHoursEnabled;

  factory SmartReminderSettingModel.fromJson(Map<String, dynamic> json) {
    bool b(String key, [bool fallback = true]) => json[key] as bool? ?? fallback;
    return SmartReminderSettingModel(
      enabled: b('enabled'),
      smartOutfit: b('smartOutfit'),
      smartLaundry: b('smartLaundry'),
      smartPacking: b('smartPacking'),
      smartTrip: b('smartTrip'),
      smartWardrobe: b('smartWardrobe'),
      smartWearHistory: b('smartWearHistory'),
      smartAIStylist: b('smartAIStylist'),
      maxDailyReminders: (json['maxDailyReminders'] as num?)?.toInt() ?? 3,
      minimumIntervalMinutes: (json['minimumIntervalMinutes'] as num?)?.toInt() ?? 120,
      quietHoursEnabled: b('quietHoursEnabled', false),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'smartOutfit': smartOutfit,
    'smartLaundry': smartLaundry,
    'smartPacking': smartPacking,
    'smartTrip': smartTrip,
    'smartWardrobe': smartWardrobe,
    'smartWearHistory': smartWearHistory,
    'smartAIStylist': smartAIStylist,
    'maxDailyReminders': maxDailyReminders,
    'minimumIntervalMinutes': minimumIntervalMinutes,
    'quietHoursEnabled': quietHoursEnabled,
  };

  SmartReminderSettingModel copyWith(Map<String, dynamic> changes) {
    final merged = {...toJson(), ...changes};
    return SmartReminderSettingModel.fromJson(merged);
  }
}
