class AdminPlan {
  const AdminPlan({
    required this.id,
    required this.name,
    required this.planCode,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.isActive,
    this.description = '',
    this.features = const [],
    this.limits = const {},
    this.sortOrder = 0,
  });

  factory AdminPlan.fromJson(Map<String, dynamic> json) {
    return AdminPlan(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      planCode: json['planCode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      billingPeriod: json['billingPeriod']?.toString() ?? 'none',
      features: (json['features'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      limits: json['limits'] is Map
          ? Map<String, dynamic>.from(json['limits'] as Map)
          : const {},
      isActive: json['isActive'] == true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String planCode;
  final String description;
  final double price;
  final String currency;
  final String billingPeriod;
  final List<String> features;
  final Map<String, dynamic> limits;
  final bool isActive;
  final int sortOrder;
}
