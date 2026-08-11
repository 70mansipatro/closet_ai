class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.action,
    required this.adminName,
    required this.adminEmail,
    required this.targetType,
    required this.targetId,
    required this.description,
    required this.createdAt,
    this.ipAddress = '',
  });

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    final admin = json['adminUserId'];
    final adminMap = admin is Map ? Map<String, dynamic>.from(admin) : null;

    return AdminAuditLog(
      id: json['_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      adminName: adminMap?['name']?.toString() ?? '',
      adminEmail: adminMap?['email']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      ipAddress: json['ipAddress']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  final String id;
  final String action;
  final String adminName;
  final String adminEmail;
  final String targetType;
  final String targetId;
  final String description;
  final String ipAddress;
  final String createdAt;
}
