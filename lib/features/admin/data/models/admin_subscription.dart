class AdminSubscription {
  const AdminSubscription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.planType,
    required this.status,
    this.planName,
    this.paymentProvider = '',
    this.providerSubscriptionId = '',
    this.startDate,
    this.endDate,
    this.autoRenew = false,
    this.amount = 0,
    this.currency = 'INR',
    this.createdAt,
  });

  factory AdminSubscription.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final plan = json['planId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final planMap = plan is Map ? Map<String, dynamic>.from(plan) : null;

    return AdminSubscription(
      id: json['_id']?.toString() ?? '',
      userId: userMap?['_id']?.toString() ?? user?.toString() ?? '',
      userName: userMap?['name']?.toString() ?? '',
      userEmail: userMap?['email']?.toString() ?? '',
      planType: json['planType']?.toString() ?? 'free',
      planName: planMap?['name']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      paymentProvider: json['paymentProvider']?.toString() ?? '',
      providerSubscriptionId: json['providerSubscriptionId']?.toString() ?? '',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      autoRenew: json['autoRenew'] == true,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      createdAt: json['createdAt']?.toString(),
    );
  }

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String planType;
  final String? planName;
  final String status;
  final String paymentProvider;
  final String providerSubscriptionId;
  final String? startDate;
  final String? endDate;
  final bool autoRenew;
  final double amount;
  final String currency;
  final String? createdAt;
}
