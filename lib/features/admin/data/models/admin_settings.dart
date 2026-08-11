class AdminSettings {
  const AdminSettings({
    required this.maintenanceModeEnabled,
    required this.maintenanceMessage,
    required this.announcementBanner,
  });

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
    final maintenance = Map<String, dynamic>.from(
      json['maintenanceMode'] as Map? ?? {},
    );
    final notifications = Map<String, dynamic>.from(
      json['notifications'] as Map? ?? {},
    );

    return AdminSettings(
      maintenanceModeEnabled: maintenance['enabled'] == true,
      maintenanceMessage: maintenance['message']?.toString() ?? '',
      announcementBanner:
          notifications['announcementBanner']?.toString() ?? '',
    );
  }

  final bool maintenanceModeEnabled;
  final String maintenanceMessage;
  final String announcementBanner;

  Map<String, dynamic> toJson() => {
    'maintenanceMode': {
      'enabled': maintenanceModeEnabled,
      'message': maintenanceMessage,
    },
    'notifications': {'announcementBanner': announcementBanner},
  };
}
