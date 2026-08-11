class SubscriptionStatusModel {
  const SubscriptionStatusModel({
    required this.plan,
    required this.status,
    this.startDate,
    this.endDate,
    this.autoRenew = false,
    this.daysRemaining = 0,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusModel(
      plan: json['plan']?.toString() ?? 'free',
      status: json['status']?.toString() ?? 'free',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      autoRenew: json['autoRenew'] == true,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
    );
  }

  final String plan;
  final String status;
  final String? startDate;
  final String? endDate;
  final bool autoRenew;
  final int daysRemaining;
}
