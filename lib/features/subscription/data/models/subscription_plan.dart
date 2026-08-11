class SubscriptionPlan {
  const SubscriptionPlan({
    required this.planCode,
    required this.name,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.features,
    required this.limits,
    this.description = '',
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      planCode: json['planCode']?.toString() ?? 'free',
      name: json['name']?.toString() ?? 'Free',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      billingPeriod: json['billingPeriod']?.toString() ?? 'none',
      features:
          (json['features'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      limits:
          (json['limits'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const <String, dynamic>{},
      description: json['description']?.toString() ?? '',
    );
  }

  final String planCode;
  final String name;
  final double price;
  final String currency;
  final String billingPeriod;
  final List<String> features;
  final Map<String, dynamic> limits;
  final String description;
}
