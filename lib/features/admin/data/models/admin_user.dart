class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.subscriptionStatus,
    required this.subscriptionPlan,
    required this.createdAt,
    this.phone = '',
    this.lastLoginAt,
    this.isVerified = false,
    this.wardrobeCount,
    this.outfitCount,
    this.tripCount,
    this.laundryCount,
    this.aiUsage = const [],
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      status: json['status']?.toString() ?? 'active',
      subscriptionStatus: json['subscriptionStatus']?.toString() ?? 'free',
      subscriptionPlan: json['subscriptionPlan']?.toString() ?? 'free',
      createdAt: json['createdAt']?.toString() ?? '',
      lastLoginAt: json['lastLoginAt']?.toString(),
      isVerified: json['isVerified'] == true,
      wardrobeCount: (json['wardrobeCount'] as num?)?.toInt(),
      outfitCount: (json['outfitCount'] as num?)?.toInt(),
      tripCount: (json['tripCount'] as num?)?.toInt(),
      laundryCount: (json['laundryCount'] as num?)?.toInt(),
      aiUsage: (json['aiUsage'] as List? ?? const [])
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String subscriptionStatus;
  final String subscriptionPlan;
  final String createdAt;
  final String? lastLoginAt;
  final bool isVerified;
  final int? wardrobeCount;
  final int? outfitCount;
  final int? tripCount;
  final int? laundryCount;
  final List<Map<String, dynamic>> aiUsage;

  bool get isPremium => subscriptionStatus == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
}
