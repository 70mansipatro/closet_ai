class PaymentVerification {
  const PaymentVerification({required this.success, this.message});

  factory PaymentVerification.fromJson(Map<String, dynamic> json) {
    return PaymentVerification(
      success: json['success'] == true,
      message: json['message']?.toString(),
    );
  }

  final bool success;
  final String? message;
}
