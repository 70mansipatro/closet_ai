class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.premiumUsers,
    required this.freeUsers,
    required this.suspendedUsers,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.successfulPayments,
    required this.failedPayments,
    required this.revenueToday,
    required this.revenueMonth,
    required this.revenueYear,
    required this.grossRevenue,
    required this.refunds,
    required this.netRevenue,
    required this.aiRequests,
    required this.wardrobeItems,
    required this.outfitsCreated,
    required this.tripsCreated,
    required this.laundryRecords,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    final users = Map<String, dynamic>.from(json['users'] as Map? ?? {});
    final subscriptions = Map<String, dynamic>.from(
      json['subscriptions'] as Map? ?? {},
    );
    final payments = Map<String, dynamic>.from(
      json['payments'] as Map? ?? {},
    );
    final revenue = Map<String, dynamic>.from(json['revenue'] as Map? ?? {});
    final ai = Map<String, dynamic>.from(json['ai'] as Map? ?? {});
    final content = Map<String, dynamic>.from(
      json['content'] as Map? ?? {},
    );

    int asInt(Map<String, dynamic> map, String key) =>
        (map[key] as num?)?.toInt() ?? 0;

    return AdminDashboardSummary(
      totalUsers: asInt(users, 'total'),
      activeUsers: asInt(users, 'active'),
      premiumUsers: asInt(users, 'premium'),
      freeUsers: asInt(users, 'free'),
      suspendedUsers: asInt(users, 'suspended'),
      activeSubscriptions: asInt(subscriptions, 'active'),
      expiredSubscriptions: asInt(subscriptions, 'expired'),
      successfulPayments: asInt(payments, 'successful'),
      failedPayments: asInt(payments, 'failed'),
      revenueToday: asInt(revenue, 'today'),
      revenueMonth: asInt(revenue, 'month'),
      revenueYear: asInt(revenue, 'year'),
      grossRevenue: asInt(revenue, 'gross'),
      refunds: asInt(revenue, 'refunds'),
      netRevenue: asInt(revenue, 'net'),
      aiRequests: asInt(ai, 'totalRequests'),
      wardrobeItems: asInt(content, 'wardrobeItems'),
      outfitsCreated: asInt(content, 'outfitsCreated'),
      tripsCreated: asInt(content, 'tripsCreated'),
      laundryRecords: asInt(content, 'laundryRecords'),
    );
  }

  final int totalUsers;
  final int activeUsers;
  final int premiumUsers;
  final int freeUsers;
  final int suspendedUsers;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final int successfulPayments;
  final int failedPayments;
  final int revenueToday;
  final int revenueMonth;
  final int revenueYear;
  final int grossRevenue;
  final int refunds;
  final int netRevenue;
  final int aiRequests;
  final int wardrobeItems;
  final int outfitsCreated;
  final int tripsCreated;
  final int laundryRecords;
}
