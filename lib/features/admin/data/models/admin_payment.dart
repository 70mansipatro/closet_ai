class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.orderId,
    required this.status,
    required this.amount,
    required this.currency,
    this.paymentId = '',
    this.provider = 'razorpay',
    this.failureReason = '',
    this.createdAt,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;

    return AdminPayment(
      id: json['_id']?.toString() ?? '',
      userId: userMap?['_id']?.toString() ?? user?.toString() ?? '',
      userName: userMap?['name']?.toString() ?? '',
      userEmail: userMap?['email']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      paymentId: json['paymentId']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'razorpay',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString() ?? 'created',
      failureReason: json['failureReason']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String orderId;
  final String paymentId;
  final String provider;
  final double amount;
  final String currency;
  final String status;
  final String failureReason;
  final String? createdAt;
}
